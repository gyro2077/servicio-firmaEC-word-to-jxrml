package ec.edu.espe.gestion_publicaciones.firmaec.integration;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

@Getter
@Setter
@Component
@ConfigurationProperties(prefix = "app.firmaec")
public class FirmaECProperties {
    private String baseUrl = "http://localhost:8180/servicio";
    private String apiKey = "";
    private String sistema = "micv1-system";
    private String version = "4.1.0";
}
