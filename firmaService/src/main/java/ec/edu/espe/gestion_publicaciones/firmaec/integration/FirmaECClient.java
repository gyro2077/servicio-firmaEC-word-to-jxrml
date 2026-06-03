package ec.edu.espe.gestion_publicaciones.firmaec.integration;

import lombok.RequiredArgsConstructor;
import org.json.JSONArray;
import org.json.JSONObject;
import org.springframework.http.*;
import org.springframework.stereotype.Component;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.RestTemplate;

import java.util.Base64;

@Component
@RequiredArgsConstructor
public class FirmaECClient {

    private final FirmaECProperties props;
    private final RestTemplate restTemplate;

    public FirmaECResponse firmar(byte[] pdfBytes, byte[] p12Bytes,
                                   String password, String cedula,
                                   int qrX, int qrY, int qrPage) {

        FirmaECResponse response = new FirmaECResponse();

        try {
            String jwt = obtenerJWT();
            if (jwt == null) {
                response.setMensajeError("No se pudo obtener token JWT de FirmaEC");
                return response;
            }

            String documentoBase64 = Base64.getEncoder().encodeToString(pdfBytes);
            String certificadoBase64 = Base64.getEncoder().encodeToString(p12Bytes);
            String passwordBase64 = Base64.getEncoder()
                .encodeToString(password.getBytes("UTF-8"));

            JSONObject systemInfo = new JSONObject();
            systemInfo.put("sistemaOperativo", "Linux");
            systemInfo.put("aplicacion", "FirmaEC-Test");
            systemInfo.put("versionApp", "4.1.0");
            String systemInfoBase64 = Base64.getEncoder()
                .encodeToString(systemInfo.toString().getBytes("UTF-8"));

            JSONObject jsonConfig = new JSONObject();
            jsonConfig.put("versionFirmaEC", props.getVersion());
            jsonConfig.put("formatoDocumento", "pdf");
            jsonConfig.put("llx", String.valueOf(qrX));
            jsonConfig.put("lly", String.valueOf(qrY));
            jsonConfig.put("pagina", String.valueOf(qrPage));
            jsonConfig.put("tipoEstampado", "QR");
            jsonConfig.put("razon", "Firma Electrónica - MICV1");

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_FORM_URLENCODED);

            MultiValueMap<String, String> body = new LinkedMultiValueMap<>();
            body.add("jwt", jwt);
            body.add("pkcs12", certificadoBase64);
            body.add("password", passwordBase64);
            body.add("documento", documentoBase64);
            body.add("json", jsonConfig.toString());
            body.add("base64", systemInfoBase64);

            HttpEntity<MultiValueMap<String, String>> request =
                new HttpEntity<>(body, headers);

            ResponseEntity<String> httpResponse = restTemplate.postForEntity(
                props.getBaseUrl() + "/appfirmardocumento",
                request, String.class);

            if (httpResponse.getStatusCode() == HttpStatus.OK) {
                JSONArray jsonArray = new JSONArray(httpResponse.getBody());
                if (jsonArray.length() > 0) {
                    JSONObject resultado = jsonArray.getJSONObject(0);

                    if (resultado.has("error") && !resultado.isNull("error")) {
                        response.setMensajeError(resultado.getString("error"));
                        return response;
                    }

                    if (resultado.has("docSigned")) {
                        response.setDocumentoFirmado(
                            Base64.getDecoder().decode(resultado.getString("docSigned")));
                    }
                    if (resultado.has("qrImage")) {
                        response.setQrImageBase64(resultado.getString("qrImage"));
                    } else if (resultado.has("qr")) {
                        response.setQrImageBase64(resultado.getString("qr"));
                    }
                    if (resultado.has("hash")) {
                        response.setHashFirma(resultado.getString("hash"));
                    }

                    response.setExitoso(true);
                }
            } else {
                response.setMensajeError("HTTP " + httpResponse.getStatusCode());
            }

        } catch (Exception e) {
            response.setMensajeError("Excepción: " + e.getMessage());
        }

        return response;
    }

    private String obtenerJWT() {
        try {
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_FORM_URLENCODED);
            headers.set("X-API-KEY", props.getApiKey());

            JSONObject payload = new JSONObject();
            payload.put("sistemaTransversal", props.getSistema());
            String base64Payload = Base64.getEncoder()
                .encodeToString(payload.toString().getBytes("UTF-8"));

            MultiValueMap<String, String> body = new LinkedMultiValueMap<>();
            body.add("base64", base64Payload);

            HttpEntity<MultiValueMap<String, String>> request =
                new HttpEntity<>(body, headers);

            ResponseEntity<String> response = restTemplate.postForEntity(
                props.getBaseUrl() + "/getjwt", request, String.class);

            if (response.getStatusCode() == HttpStatus.OK) {
                JSONObject jsonResponse = new JSONObject(response.getBody());
                return jsonResponse.getString("response");
            }
        } catch (Exception e) {
            System.err.println("FirmaECClient: Error obteniendo JWT - " + e.getMessage());
        }
        return null;
    }
}
