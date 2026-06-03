package ec.edu.espe.gestion_publicaciones.firmaec.service;

import ec.edu.espe.gestion_publicaciones.firmaec.integration.FirmaECClient;
import ec.edu.espe.gestion_publicaciones.firmaec.integration.FirmaECResponse;
import ec.edu.espe.gestion_publicaciones.firmaec.model.entity.DocumentoFirmableEntity;
import ec.edu.espe.gestion_publicaciones.firmaec.model.entity.FirmaElectronicaEntity;
import ec.edu.espe.gestion_publicaciones.firmaec.repository.DocumentoFirmableRepository;
import ec.edu.espe.gestion_publicaciones.firmaec.repository.FirmaElectronicaRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Base64;

@Service
@RequiredArgsConstructor
public class FirmaElectronicaService {

    private final DocumentoFirmableRepository documentoRepo;
    private final FirmaElectronicaRepository firmaRepo;
    private final PdfSignatureLocator signatureLocator;
    private final FirmaECClient firmaECClient;

    @Transactional
    public FirmaECResponse firmarDocumento(Long documentoFirmableId,
                                            String cedulaUsuario,
                                            byte[] p12Bytes,
                                            String password) {

        DocumentoFirmableEntity doc = documentoRepo.findById(documentoFirmableId)
            .orElseThrow(() -> new RuntimeException(
                "Documento firmable no encontrado: " + documentoFirmableId));

        if ("COMPLETADO".equals(doc.getEstado())) {
            throw new RuntimeException("El documento ya fue completamente firmado.");
        }

        FirmaElectronicaEntity firmaPendiente = firmaRepo
            .findByDocumentoFirmableIdAndCedulaFirmanteAndEstado(
                documentoFirmableId, cedulaUsuario, "PENDIENTE")
            .orElseThrow(() -> new RuntimeException(
                "No hay firma pendiente para cédula: " + cedulaUsuario));

        byte[] pdfBytes = Base64.getDecoder().decode(doc.getPdfBase64());
        byte[] pdfNormalizado = signatureLocator.normalizarRotacion(pdfBytes);
        if (pdfNormalizado != pdfBytes) {
            doc.setPdfBase64(Base64.getEncoder().encodeToString(pdfNormalizado));
            pdfBytes = pdfNormalizado;
        }
        int turno = firmaPendiente.getOrdenFirma();

        boolean doble = signatureLocator.esDobleEstampado(pdfBytes, turno);

        FirmaECResponse response;

        if (doble) {
            int[] coordsA = signatureLocator.localizarFirma(pdfBytes, turno, "A");
            if (coordsA == null) {
                throw new RuntimeException(
                    "No se encontró etiqueta [F" + turno + "A] en el PDF.");
            }

            response = firmaECClient.firmar(
                pdfBytes, p12Bytes, password, cedulaUsuario,
                coordsA[0], coordsA[1], coordsA[2]);

            if (response.isExitoso()) {
                byte[] pdfIntermedio = response.getDocumentoFirmado();
                int[] coordsB = signatureLocator.localizarFirma(pdfIntermedio, turno, "B");
                if (coordsB == null) {
                    throw new RuntimeException(
                        "No se encontró etiqueta [F" + turno + "B] en el PDF.");
                }
                response = firmaECClient.firmar(
                    pdfIntermedio, p12Bytes, password, cedulaUsuario,
                    coordsB[0], coordsB[1], coordsB[2]);
            }
        } else {
            int[] coords = signatureLocator.localizarFirma(pdfBytes, turno);
            if (coords == null) {
                throw new RuntimeException(
                    "No se encontró etiqueta [F" + turno + "] en el PDF.");
            }

            response = firmaECClient.firmar(
                pdfBytes, p12Bytes, password, cedulaUsuario,
                coords[0], coords[1], coords[2]);
        }

        if (response.isExitoso()) {
            String base64Firmado = Base64.getEncoder()
                .encodeToString(response.getDocumentoFirmado());
            doc.setPdfBase64(base64Firmado);
            doc.setFirmasCompletadas(doc.getFirmasCompletadas() + 1);

            if (doc.getFirmasCompletadas() >= doc.getTotalFirmasRequeridas()) {
                doc.setEstado("COMPLETADO");
            } else {
                doc.setEstado("EN_PROCESO");
            }
            documentoRepo.save(doc);

            firmaPendiente.setEstado("FIRMADO");
            firmaPendiente.setFechaFirma(LocalDateTime.now());
            firmaPendiente.setHashFirma(response.getHashFirma());
            firmaPendiente.setQrBase64(response.getQrImageBase64());
            
            // Guardar las coordenadas que se detectaron y enviaron a FirmaEC
            if (doble) {
                int[] coordsA = signatureLocator.localizarFirma(pdfBytes, turno, "A");
                if (coordsA != null) {
                    firmaPendiente.setCoordenadaX(coordsA[0]);
                    firmaPendiente.setCoordenadaY(coordsA[1]);
                    firmaPendiente.setPaginaFirma(coordsA[2]);
                }
            } else {
                int[] coords = signatureLocator.localizarFirma(pdfBytes, turno);
                if (coords != null) {
                    firmaPendiente.setCoordenadaX(coords[0]);
                    firmaPendiente.setCoordenadaY(coords[1]);
                    firmaPendiente.setPaginaFirma(coords[2]);
                }
            }
            
            firmaRepo.save(firmaPendiente);
        }

        return response;
    }

    @Transactional
    public DocumentoFirmableEntity crearDocumentoFirmable(
            Long idSolicitud,
            Long idTipoDocumento,
            byte[] pdfBytes,
            String nombreArchivo,
            FirmanteInfo... firmantes) {

        DocumentoFirmableEntity doc = new DocumentoFirmableEntity();
        doc.setIdSolicitud(idSolicitud);
        doc.setIdTipoDocumento(idTipoDocumento);
        doc.setPdfBase64(Base64.getEncoder().encodeToString(pdfBytes));
        doc.setNombreArchivo(nombreArchivo);
        doc.setTotalFirmasRequeridas(firmantes.length);
        doc.setEstado("PENDIENTE");

        for (int i = 0; i < firmantes.length; i++) {
            FirmaElectronicaEntity firma = new FirmaElectronicaEntity();
            firma.setDocumentoFirmable(doc);
            firma.setOrdenFirma(i + 1);
            firma.setCedulaFirmante(firmantes[i].cedula());
            firma.setNombreFirmante(firmantes[i].nombre());
            firma.setRolFirma(firmantes[i].rol());
            firma.setEtiquetaAncla("[F" + (i + 1) + "]");
            firma.setEstado("PENDIENTE");
            doc.getFirmas().add(firma);
        }

        return documentoRepo.save(doc);
    }

    public DocumentoFirmableEntity obtenerDocumento(Long id) {
        return documentoRepo.findById(id)
            .orElseThrow(() -> new RuntimeException("Documento firmable no encontrado: " + id));
    }

    public record FirmanteInfo(String cedula, String nombre, String rol) {}
}
