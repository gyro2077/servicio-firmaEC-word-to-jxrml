package ec.edu.espe.gestion_publicaciones.firmaec.model.dto;

import lombok.Getter;
import lombok.Setter;

import java.time.LocalDateTime;
import java.util.List;

@Getter
@Setter
public class DocumentoFirmableResponse {
    private Long id;
    private Long idSolicitud;
    private Long idTipoDocumento;
    private String nombreArchivo;
    private int totalFirmasRequeridas;
    private int firmasCompletadas;
    private String estado;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    private String pdfBase64;
    private List<FirmaElectronicaResponse> firmas;
}
