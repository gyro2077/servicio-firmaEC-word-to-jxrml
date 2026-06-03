# Plan de Ejecución Paso a Paso: Microservicio `firmaService`

**Objetivo:** Instrucciones detalladas ("Divide y Vencerás") para que un agente o desarrollador implemente la librería genérica de firmas como un **microservicio independiente** (`firmaService`). Este servicio compartirá la base de datos PostgreSQL con `MICV1`, pero tendrá su propio ciclo de vida, repositorio y API REST.

**Ubicación del nuevo servicio:** `@[/home/gyro/Documents/TESIS/word-to-jrxml/firmaService]`

---

## FASE 1: Inicialización del Proyecto Spring Boot

**Agente a cargo:** Encargado de crear la estructura base del proyecto Maven y configurar las dependencias.

### 1.1 Crear Estructura de Directorios
Ejecutar en la terminal de Linux:
```bash
cd /home/gyro/Documents/TESIS/word-to-jrxml
mkdir -p firmaService/src/main/java/ec/edu/espe/gestion_publicaciones/firmaec/{controller,model/entity,model/dto,repository,service,integration,mapper}
mkdir -p firmaService/src/main/resources/db/migration
```

### 1.2 Crear el `pom.xml`
Crear el archivo `firmaService/pom.xml`. Debe tener Spring Boot (misma versión que MICV1, Java 21) y las dependencias clave:
- `spring-boot-starter-web` (REST API)
- `spring-boot-starter-data-jpa` (Base de datos)
- `postgresql` (Driver BD)
- `flyway-database-postgresql` (Migraciones, si el servicio manejará sus propias tablas)
- `org.apache.pdfbox:pdfbox:3.0.4` (Para el escáner de coordenadas)
- `org.json:json:20240303` (Para parsear respuestas de FirmaEC)
- `lombok`

### 1.3 Configurar `application.yaml`
Crear `firmaService/src/main/resources/application.yaml`. El servicio debe apuntar a la misma base de datos que MICV1 (`gestion_revistas` en el puerto `5433` definido en el `docker-compose.yml`):
```yaml
server:
  port: 8081 # MICV1 usa 8080, este usa 8081
spring:
  application:
    name: firma-service
  datasource:
    url: jdbc:postgresql://localhost:5433/gestion_revistas
    username: postgres
    password: postgres
  jpa:
    hibernate:
      ddl-auto: none
    properties:
      hibernate:
        default_schema: publicaciones
app:
  firmaec:
    base-url: http://localhost:8180/servicio
    api-key: "1b6e325b1851d6f167c0a2c8e3ceb8ca727e92106992bf973b028c1bb7aff849"
    sistema: micv1-system
```

---

## FASE 2: Base de Datos y Entidades JPA

**Agente a cargo:** Encargado de preparar el esquema de BD y el mapeo objeto-relacional.

### 2.1 Migración Flyway
Crear el script SQL para generar las tablas específicas del servicio de firmas.
- **Ruta:** `firmaService/src/main/resources/db/migration/V1__init_schema_firmas.sql`
- **Contenido:** Crear las tablas `documentos_firmables` y `firmas_electronicas` en el esquema `publicaciones`. (Ver [01_PLAN_LIBRERIA_FIRMA_ELECTRONICA.md] sección 8.1).
*Nota: Como comparte BD con MICV1, podemos usar un foreign key lógico hacia `solicitudes` y `tipos_documento`, pero a nivel de JPA podemos mapear solo los IDs (Long) para no tener que importar todas las entidades de MICV1 al microservicio.*

### 2.2 Crear Entidades JPA (`model/entity/`)
- Crear `DocumentoFirmableEntity.java`.
- Crear `FirmaElectronicaEntity.java`.
- **Simplificación arquitectónica:** En lugar de hacer relaciones `@ManyToOne` hacia `SolicitudEntity` (que pertenece a MICV1), mapear `id_solicitud` y `id_tipo_documento` como tipos `Long` básicos. Esto mantiene el microservicio totalmente desacoplado a nivel de código, compartiendo solo los identificadores a nivel de BD.

### 2.3 Crear Repositorios (`repository/`)
- Crear `DocumentoFirmableRepository.java` extends `JpaRepository`.
- Crear `FirmaElectronicaRepository.java` extends `JpaRepository`.

---

## FASE 3: Core del Servicio (Escáner PDF y Cliente FirmaEC)

**Agente a cargo:** Encargado de portar la lógica algorítmica de SISPP.

### 3.1 Implementar `PdfSignatureLocator` (`service/`)
- Crear la clase basándose en el port de `PDFTextLocationFinder`.
- Lógica principal: Cargar el `byte[]` en un `PDDocument` de PDFBox, extender `PDFTextStripper` para interceptar las posiciones, y buscar la etiqueta enviada como parámetro (Ej: `"[F1]"`).
- Devolver `int[] {x, y_pdf, pagina}` ajustando el *offset* en Y (`+15`).

### 3.2 Implementar `FirmaECClient` (`integration/`)
- Crear clase `FirmaECProperties` para inyectar configuración del `application.yaml`.
- Crear `FirmaECClient.java` usando `RestTemplate`.
- Flujo:
  1. POST a `/getjwt` enviando `X-API-KEY` y `sistemaTransversal`.
  2. Construir `jsonConfig` con las coordenadas `llx`, `lly`, `pagina`.
  3. POST a `/appfirmardocumento` enviando formato URL-Encoded con el JWT, PKCS12 (base64), password (base64), PDF (base64) y JSON.
  4. Parsear el array JSON de respuesta para extraer `docSigned`, `qrImage` y `hash`.

---

## FASE 4: Orquestación y API REST

**Agente a cargo:** Encargado de exponer la lógica de negocio para que MICV1 o un Frontend la consuman.

### 4.1 Implementar `FirmaElectronicaService` (`service/`)
- Método transaccional `firmarDocumento(...)`:
  - Recibe: ID del documento, cédula del firmante, archivo .p12 y contraseña.
  - Busca en BD qué turno (orden_firma) le toca a esa cédula que esté "PENDIENTE".
  - Extrae el PDF en Base64 actual.
  - Llama a `PdfSignatureLocator.localizarFirma(pdfBytes, turno)`.
  - Si encuentra las coordenadas, llama a `FirmaECClient.firmar(...)`.
  - Actualiza el PDF en Base64 en `documentos_firmables` y marca el detalle como "FIRMADO".
  - Maneja la lógica opcional de doble estampado (Ej. si encuentra `[F1A]`).

### 4.2 Implementar `FirmaElectronicaController` (`controller/`)
- Crear el API REST.
- Endpoints sugeridos:
  - `POST /api/v1/firmas/documento/{id}/firmar` (multipart form-data para recibir el .p12).
  - `POST /api/v1/firmas/documento` (Para inicializar un documento firmable con su lista de firmantes. Quien genere el Jasper llamará a esto).
  - `GET /api/v1/firmas/documento/{id}/estado` (Para consultar el avance de firmas).

### 4.3 Testeo y Compilación
- Instrucciones de terminal para verificar la construcción:
```bash
cd /home/gyro/Documents/TESIS/word-to-jrxml/firmaService
./mvnw clean install -DskipTests
./mvnw spring-boot:run
```

---

## FASE 5: Adaptación de JRXMLs en `word-to-jrxml`

**Agente a cargo:** Encargado de modificar las plantillas para aprovechar el nuevo motor genérico.

### 5.1 Edición de Plantillas (.jrxml)
1. Para cada archivo `.jrxml` en `/home/gyro/Documents/TESIS/word-to-jrxml/`, localizar los bloques donde actualmente se pinta la línea vacía de firma o el nombre.
2. Añadir un elemento `<staticText>` que contenga:
   - Para el primer firmante: `[F1]`
   - Para el segundo firmante: `[F2]`
   - Etc.
3. **Propiedades XML del texto:** Color de fuente blanco (`#FFFFFF`) o tamaño `1` para que sea invisible al ojo humano, pero legible por PDFBox.
   ```xml
   <textElement textAlignment="Center">
       <font size="6" forecolor="#FFFFFF" />
   </textElement>
   <text><![CDATA[[F1]]]></text>
   ```

### 5.2 Recompilación
Usar el entorno autónomo existente para verificar:
```bash
cd /home/gyro/Documents/TESIS/word-to-jrxml/JASPER
# Compilar un JRXML a .jasper usando el script existente
./recompilar_jasper.sh "../4. SOLICITUD DE FONDOS/solicitudFondos.jrxml"
```

---

## Metodología de Ejecución para el Agente

Cuando le ordenes a un agente que ejecute este plan, el agente deberá hacerlo **estrictamente en orden**:

1. **Fase 1 y 2:** El agente usará comandos bash (`mkdir`, `touch`, `echo`) para crear el esqueleto, el `pom.xml`, el `application.yaml` y el script Flyway. Luego usará `write_to_file` para generar las clases `DocumentoFirmableEntity` y `FirmaElectronicaEntity` de forma aislada (mapeando con Longs, sin dependencias a MICV1).
2. **Fase 3:** El agente escribirá las clases utilitarias `PdfSignatureLocator` y `FirmaECClient` copiando la lógica algorítmica y adaptándola a las librerías modernas de Spring.
3. **Fase 4:** El agente implementará el controlador y el servicio. Tras esto, correrá `mvn clean compile` para asegurarse de que el microservicio compile sin errores de dependencias.
4. **Fase 5:** Una vez que el servicio compile, el agente modificará los JRXML (puede hacerlo leyendo el archivo con `grep_search` y aplicando reemplazos en las bandas `<summary>` o `<detail>`).

**Estado de este Plan:** LISTO PARA EJECUCIÓN POR UN AGENTE.
