package ec.edu.espe.gestion_publicaciones.firmaec.model.dto;

import lombok.Getter;
import lombok.Setter;

import java.time.LocalDateTime;

@Getter
@Setter
public class FirmaElectronicaResponse {
    private Long id;
    private int ordenFirma;
    private String cedulaFirmante;
    private String nombreFirmante;
    private String rolFirma;
    private String estado;
    private LocalDateTime fechaFirma;
    private String hashFirma;
    private String etiquetaAncla;
    private Integer coordenadaX;
    private Integer coordenadaY;
    private Integer paginaFirma;
}
