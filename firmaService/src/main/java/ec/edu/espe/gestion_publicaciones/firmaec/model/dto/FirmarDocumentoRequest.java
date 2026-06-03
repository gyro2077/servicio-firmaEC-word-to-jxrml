package ec.edu.espe.gestion_publicaciones.firmaec.model.dto;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class FirmarDocumentoRequest {
    private String cedulaFirmante;
    private byte[] p12Bytes;
    private String password;
}
