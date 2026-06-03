package ec.edu.espe.gestion_publicaciones.firmaec.integration;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class FirmaECResponse {

    private boolean exitoso;
    private byte[] documentoFirmado;
    private String qrImageBase64;
    private String hashFirma;
    private String mensajeError;
}
