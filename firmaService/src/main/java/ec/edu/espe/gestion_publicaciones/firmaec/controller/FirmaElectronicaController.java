package ec.edu.espe.gestion_publicaciones.firmaec.controller;

import ec.edu.espe.gestion_publicaciones.firmaec.integration.FirmaECResponse;
import ec.edu.espe.gestion_publicaciones.firmaec.model.dto.CrearDocumentoFirmableRequest;
import ec.edu.espe.gestion_publicaciones.firmaec.model.dto.DocumentoFirmableResponse;
import ec.edu.espe.gestion_publicaciones.firmaec.model.dto.FirmaElectronicaResponse;
import ec.edu.espe.gestion_publicaciones.firmaec.model.entity.DocumentoFirmableEntity;
import ec.edu.espe.gestion_publicaciones.firmaec.model.entity.FirmaElectronicaEntity;
import ec.edu.espe.gestion_publicaciones.firmaec.service.FirmaElectronicaService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.Base64;
import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/v1/firmas")
@RequiredArgsConstructor
public class FirmaElectronicaController {

    private final FirmaElectronicaService firmaService;

    @PostMapping("/documento")
    public ResponseEntity<DocumentoFirmableResponse> crearDocumento(
            @RequestBody CrearDocumentoFirmableRequest request) {

        FirmaElectronicaService.FirmanteInfo[] firmantes =
            request.getFirmantes().stream()
                .map(f -> new FirmaElectronicaService.FirmanteInfo(
                    f.getCedula(), f.getNombre(), f.getRol()))
                .toArray(FirmaElectronicaService.FirmanteInfo[]::new);

        byte[] pdfBytes = Base64.getDecoder().decode(request.getPdfBase64());

        DocumentoFirmableEntity doc = firmaService.crearDocumentoFirmable(
            request.getIdSolicitud(),
            request.getIdTipoDocumento(),
            pdfBytes,
            request.getNombreArchivo(),
            firmantes);

        return ResponseEntity.status(HttpStatus.CREATED).body(toResponse(doc));
    }

    @PostMapping("/documento/{id}/firmar")
    public ResponseEntity<FirmaECResponse> firmarDocumento(
            @PathVariable Long id,
            @RequestParam("cedula") String cedula,
            @RequestParam("p12") MultipartFile p12File,
            @RequestParam("password") String password) throws IOException {

        byte[] p12Bytes = p12File.getBytes();

        FirmaECResponse response = firmaService.firmarDocumento(
            id, cedula, p12Bytes, password);

        if (response.isExitoso()) {
            return ResponseEntity.ok(response);
        } else {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(response);
        }
    }

    @GetMapping("/documento/{id}/estado")
    public ResponseEntity<DocumentoFirmableResponse> obtenerEstado(
            @PathVariable Long id) {

        DocumentoFirmableEntity doc = firmaService.obtenerDocumento(id);
        return ResponseEntity.ok(toResponse(doc));
    }

    private DocumentoFirmableResponse toResponse(DocumentoFirmableEntity entity) {
        DocumentoFirmableResponse resp = new DocumentoFirmableResponse();
        resp.setId(entity.getId());
        resp.setIdSolicitud(entity.getIdSolicitud());
        resp.setIdTipoDocumento(entity.getIdTipoDocumento());
        resp.setNombreArchivo(entity.getNombreArchivo());
        resp.setTotalFirmasRequeridas(entity.getTotalFirmasRequeridas());
        resp.setFirmasCompletadas(entity.getFirmasCompletadas());
        resp.setEstado(entity.getEstado());
        resp.setCreatedAt(entity.getCreatedAt());
        resp.setUpdatedAt(entity.getUpdatedAt());
        resp.setPdfBase64(entity.getPdfBase64());

        if (entity.getFirmas() != null) {
            resp.setFirmas(entity.getFirmas().stream()
                .map(this::toFirmaResponse)
                .collect(Collectors.toList()));
        }

        return resp;
    }

    private FirmaElectronicaResponse toFirmaResponse(FirmaElectronicaEntity entity) {
        FirmaElectronicaResponse resp = new FirmaElectronicaResponse();
        resp.setId(entity.getId());
        resp.setOrdenFirma(entity.getOrdenFirma());
        resp.setCedulaFirmante(entity.getCedulaFirmante());
        resp.setNombreFirmante(entity.getNombreFirmante());
        resp.setRolFirma(entity.getRolFirma());
        resp.setEstado(entity.getEstado());
        resp.setFechaFirma(entity.getFechaFirma());
        resp.setHashFirma(entity.getHashFirma());
        resp.setEtiquetaAncla(entity.getEtiquetaAncla());
        resp.setCoordenadaX(entity.getCoordenadaX());
        resp.setCoordenadaY(entity.getCoordenadaY());
        resp.setPaginaFirma(entity.getPaginaFirma());
        return resp;
    }
}
