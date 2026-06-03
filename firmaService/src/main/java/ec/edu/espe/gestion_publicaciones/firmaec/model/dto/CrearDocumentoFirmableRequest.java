package ec.edu.espe.gestion_publicaciones.firmaec.model.dto;

import lombok.Getter;
import lombok.Setter;

import java.util.List;

@Getter
@Setter
public class CrearDocumentoFirmableRequest {
    private Long idSolicitud;
    private Long idTipoDocumento;
    private String pdfBase64;
    private String nombreArchivo;
    private List<FirmanteRequest> firmantes;

    @Getter
    @Setter
    public static class FirmanteRequest {
        private String cedula;
        private String nombre;
        private String rol;
    }
}
