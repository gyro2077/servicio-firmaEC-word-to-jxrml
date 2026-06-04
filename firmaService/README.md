# firmaService — Microservicio de Firma Electrónica

## ¿Qué es?

**firmaService** es un microservicio Spring Boot que orquesta la firma electrónica de documentos PDF. Su función principal es:

1. Recibir un PDF junto con una lista de personas que deben firmarlo.
2. Escanear el PDF buscando etiquetas de anclaje invisibles (`[F1]`, `[F2]`, `[F3]`…).
3. Enviar el PDF + coordenadas detectadas al servicio externo **FirmaEC** para estampar el sello QR y la firma electrónica.
4. Guardar el PDF firmado en la base de datos y permitir que el siguiente firmante firme sobre la versión ya firmada.

No necesita saber qué tipo de documento es (orden de gasto, solicitud, etc.). Solo busca las etiquetas `[FN]` en el PDF.

---

## Arquitectura general

```
┌──────────────────────────────────────────────────────────────────┐
│                        firmaService                              │
│                                                                  │
│  POST /api/v1/firmas/documento                                   │
│  ──────────────────────────►  FirmaElectronicaController         │
│                                  │                               │
│                                  ▼                               │
│                         FirmaElectronicaService                  │
│                         (orquestación central)                   │
│                           │           │                          │
│                    ┌──────▼───┐  ┌────▼──────────┐               │
│                    │          │  │               │               │
│                    │  PDF     │  │  FirmaECClient│               │
│                    │  Signature│  │  (cliente     │               │
│                    │  Locator │  │   HTTP)       │               │
│                    │  (PDFBox)│  │               │               │
│                    └──────────┘  └────┬──────────┘               │
│                                       │                          │
│                                       ▼                          │
│                              ┌─────────────────┐                 │
│                              │ FirmaEC (WildFly)│                │
│                              │ Puerto 8180      │                │
│                              └─────────────────┘                 │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐    │
│  │              PostgreSQL (puerto 5433)                    │    │
│  │  publicaciones.documentos_firmables (maestro)            │    │
│  │  publicaciones.firmas_electronicas  (detalle)            │    │
│  └──────────────────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────────────────┘
```

---

## Flujo completo de una firma (paso a paso)

### 1. Creación del documento firmable

Un sistema externo (frontend, script, etc.) llama a:

```
POST /api/v1/firmas/documento
Body: {
  "pdfBase64": "<PDF en Base64>",
  "nombreArchivo": "ordenGasto.pdf",
  "firmantes": [
    { "cedula": "1234567890", "nombre": "Juan Perez",  "rol": "SOLICITADO_POR" },
    { "cedula": "0987654321", "nombre": "Maria Garcia", "rol": "PREPARADO_POR" },
    { "cedula": "1122334455", "nombre": "Carlos Lopez", "rol": "AUTORIZADO_POR" }
  ]
}
```

**¿Qué pasa internamente?**

1. `FirmaElectronicaController.crearDocumento()` recibe el JSON.
2. Convierte la lista de firmantes a un array de `FirmanteInfo`.
3. Decodifica el PDF de Base64 a bytes.
4. Llama a `FirmaElectronicaService.crearDocumentoFirmable()`.
5. El servicio crea una entidad `DocumentoFirmableEntity` con `estado = "PENDIENTE"`.
6. Por cada firmante, crea una `FirmaElectronicaEntity` con `ordenFirma = 1, 2, 3…` y `etiquetaAncla = "[F1]", "[F2]", "[F3]"…`.
7. Guarda todo en la base de datos (maestro + detalle en una sola transacción).
8. Responde con el ID del documento creado y los detalles.

### 2. Firma del turno 1 (ej: SOLICITADO_POR con [F1])

```
POST /api/v1/firmas/documento/{id}/firmar
Form-data: cedula=1234567890, p12=@cert.p12, password=***
```

**¿Qué pasa internamente?** — `FirmaElectronicaService.firmarDocumento()`:

1. **Carga el documento** de la DB por ID. Si el estado es "COMPLETADO", rechaza.
2. **Busca la firma pendiente** del usuario: encuentra la `FirmaElectronicaEntity` donde `id_documento_firmable = {id}`, `cedula_firmante = "1234567890"` y `estado = "PENDIENTE"`.
3. **Decodifica el PDF** actual de `pdf_base64` en la DB.
4. **Normaliza la rotación** del PDF (por si está escaneado rotado 90/180/270°).
5. **Detecta coordenadas**: llama a `PdfSignatureLocator.localizarFirma(pdfBytes, turno=1)`.
   - PDFBox carga el PDF.
   - `TextPositionExtractor` extiende `PDFTextStripper` para interceptar cada carácter renderizado.
   - Busca el texto `"[F1]"` en todas las páginas.
   - Cuando lo encuentra, obtiene su posición X, Y (en sistema PDF con Y↑ desde abajo).
   - Aplica un offset de +15 en Y para centrar el QR sobre la etiqueta.
   - Devuelve `{x, y, página}`.
6. **Envía a FirmaEC**: llama a `FirmaECClient.firmar()` con el PDF, certificado, contraseña y coordenadas.
   - `FirmaECClient` primero obtiene un JWT de `POST /servicio/getjwt`.
   - Prepara un `jsonConfig` con las coordenadas (`llx`, `lly`, `pagina`).
   - Envía todo a `POST /servicio/appfirmardocumento` en formato URL-Encoded.
   - FirmaEC devuelve el PDF firmado (con sello QR) en Base64.
7. **Guarda el resultado**: si la firma fue exitosa:
   - Actualiza `pdf_base64` en `documentos_firmables` con el nuevo PDF firmado.
   - Incrementa `firmas_completadas` de 0 a 1.
   - Cambia `estado` de "PENDIENTE" a "EN_PROCESO".
   - Marca la firma individual como "FIRMADO", guarda `fecha_firma`, `hash_firma`, `qr_base64` y coordenadas.

### 3. Firmas subsiguientes (turno 2, turno 3)

El proceso es idéntico al turno 1, pero:

- El PDF que se firma ahora **es el PDF ya firmado** del turno anterior (con el sello QR ya estampado).
- Se busca la etiqueta `[F2]` (o `[F3]`).
- Cuando `firmas_completadas` alcanza `total_firmas_requeridas`, el `estado` pasa a "COMPLETADO".

Esto permite que **N firmantes firmen secuencialmente** sobre el mismo documento acumulativo.

### 4. Consulta de estado

```
GET /api/v1/firmas/documento/{id}/estado
```

Devuelve el estado actual del documento, las firmas realizadas, y el PDF acumulado en Base64.

---

## Componentes del código

### `FirmaServiceApplication.java`
Punto de entrada Spring Boot. `@SpringBootApplication` escanea todo el paquete `ec.edu.espe.gestion_publicaciones.firmaec`.

### Controller: `FirmaElectronicaController.java`
Expone 3 endpoints REST:

| Método | Ruta | Función |
|--------|------|---------|
| `POST` | `/api/v1/firmas/documento` | Crear un documento firmable con sus firmantes |
| `POST` | `/api/v1/firmas/documento/{id}/firmar` | Firmar el documento (multipart: cedula + p12 + password) |
| `GET` | `/api/v1/firmas/documento/{id}/estado` | Consultar estado y descargar PDF acumulado |

### Service: `FirmaElectronicaService.java`
Cerebro de la aplicación. Contiene la lógica de negocio:

- **`crearDocumentoFirmable()`**: Crea el documento + N firmantes asociados en una transacción.
- **`firmarDocumento()`**: Orquesta el flujo completo:
  - Carga documento y firma pendiente de DB
  - Decodifica PDF acumulado
  - Detecta coordenadas con `PdfSignatureLocator`
  - Envía a FirmaEC via `FirmaECClient`
  - Actualiza DB con resultado
  - Soporta **doble estampado** (si existen `[FNA]` y `[FNB]`)
- **`obtenerDocumento()`**: Consulta simple por ID.

### Service: `PdfSignatureLocator.java`
Escáner de coordenadas usando **Apache PDFBox 3.x**.

**Métodos clave:**
- `localizarFirma(pdfBytes, turno)` → Busca `[F1]`, `[F2]`, etc. y devuelve `{x, y, pagina}`
- `localizarFirma(pdfBytes, turno, "A")` → Busca `[F1A]` para doble estampado
- `esDobleEstampado(pdfBytes, turno)` → Verifica si existen `[FNA]` y `[FNB]`
- `detectarTotalFirmas(pdfBytes)` → Cuenta cuántas etiquetas `[FN]` existen
- `normalizarRotacion(pdfBytes)` → Corrige PDFs rotados 90/180/270°

**Clase interna `TextPositionExtractor`**: extiende `PDFTextStripper` para interceptar la posición de cada carácter renderizado en el PDF. Cuando encuentra el texto buscado, guarda su coordenada.

### Integration: `FirmaECClient.java`
Cliente HTTP para el servicio externo FirmaEC (WildFly en puerto 8180).

**Flujo:**
1. Obtiene JWT de `POST /servicio/getjwt` usando `X-API-KEY`
2. Construye el payload con PDF (Base64), certificado (.p12), password y configuración JSON con coordenadas
3. Envía a `POST /servicio/appfirmardocumento`
4. Parsea la respuesta: extrae `docSigned` (PDF firmado), `qrImage` y `hash`

### Integration: `FirmaECProperties.java`
Configuración externalizada con prefijo `app.firmaec`. Valores desde `application.yaml`:

```yaml
app:
  firmaec:
    base-url: http://localhost:8180/servicio
    api-key: "..."
    sistema: test-system
    version: 4.1.0
```

### Integration: `FirmaECResponse.java`
DTO que encapsula la respuesta de FirmaEC:
- `exitoso` (boolean), `documentoFirmado` (byte[]), `qrImageBase64` (String), `hashFirma` (String), `mensajeError` (String)

### Integration: `RestTemplateConfig.java`
Configura un bean `RestTemplate` para las llamadas HTTP a FirmaEC.

### Entities (JPA)

**`DocumentoFirmableEntity`** — Tabla maestra `documentos_firmables`:

| Campo | Tipo | Descripción |
|-------|------|-------------|
| id | Long (PK) | Auto-incremental |
| idSolicitud | Long | FK lógica a solicitudes (sin relación JPA) |
| idTipoDocumento | Long | FK lógica a tipos de documento |
| pdfBase64 | TEXT | PDF acumulado en Base64 (se actualiza con cada firma) |
| nombreArchivo | String | Nombre del archivo original |
| totalFirmasRequeridas | int | Cuántas firmas necesita |
| firmasCompletadas | int | Cuántas se han realizado |
| estado | String | PENDIENTE → EN_PROCESO → COMPLETADO |
| firmas | List\<FirmaElectronicaEntity> | Detalle en cascada |

**`FirmaElectronicaEntity`** — Tabla detalle `firmas_electronicas`:

| Campo | Tipo | Descripción |
|-------|------|-------------|
| id | Long (PK) | Auto-incremental |
| documentoFirmable | DocumentoFirmableEntity (FK) | Documento padre |
| ordenFirma | int | 1, 2, 3… |
| cedulaFirmante | String | Cédula del firmante |
| nombreFirmante | String | Nombre del firmante |
| rolFirma | String | SOLICITADO_POR, PREPARADO_POR, AUTORIZADO_POR |
| estado | String | PENDIENTE → FIRMADO |
| fechaFirma | LocalDateTime | Cuándo firmó |
| hashFirma | String | Hash SHA-256 del PDF firmado |
| qrBase64 | TEXT | Imagen QR en Base64 |
| etiquetaAncla | String | "[F1]", "[F2]", etc. |
| coordenadaX/Y | Integer | Dónde se estampó el QR |
| paginaFirma | Integer | En qué página |

### Repositories

- **`DocumentoFirmableRepository`**: Búsquedas por estado, por idSolicitud
- **`FirmaElectronicaRepository`**: Búsquedas por documento, por cédula+estado

### DTOs

- **`CrearDocumentoFirmableRequest`**: Request para crear documento (incluye `FirmanteRequest` interno)
- **`FirmarDocumentoRequest`**: Datos para firmar (cédula, .p12, password)
- **`DocumentoFirmableResponse`**: Respuesta con datos del documento + `pdfBase64`
- **`FirmaElectronicaResponse`**: Respuesta con datos de cada firma individual

---

## Base de datos

### Tablas en schema `publicaciones`

```sql
-- Maestro: un documento que requiere firmas
documentos_firmables (
    id_documento_firmable  BIGSERIAL PRIMARY KEY,
    id_solicitud           BIGINT,          -- FK lógica a solicitudes
    id_tipo_documento      BIGINT NOT NULL, -- FK lógica a tipos_documento
    pdf_base64             TEXT,            -- PDF acumulado
    nombre_archivo         VARCHAR(255),
    total_firmas_requeridas INTEGER,
    firmas_completadas     INTEGER DEFAULT 0,
    estado                 VARCHAR(30) DEFAULT 'PENDIENTE',
    created_at             TIMESTAMP,
    updated_at             TIMESTAMP
);

-- Detalle: cada firma individual
firmas_electronicas (
    id_firma_electronica   BIGSERIAL PRIMARY KEY,
    id_documento_firmable  BIGINT NOT NULL REFERENCES documentos_firmables(...),
    orden_firma            INTEGER NOT NULL,
    cedula_firmante        VARCHAR(15) NOT NULL,
    nombre_firmante        VARCHAR(200),
    rol_firma              VARCHAR(100),
    estado                 VARCHAR(20) DEFAULT 'PENDIENTE',
    fecha_firma            TIMESTAMP,
    hash_firma             VARCHAR(256),
    qr_base64              TEXT,
    etiqueta_ancla         VARCHAR(10),
    coordenada_x           INTEGER,
    coordenada_y           INTEGER,
    pagina_firma           INTEGER,
    created_at             TIMESTAMP,
    UNIQUE (id_documento_firmable, orden_firma)
);
```

### Estados del documento

```
PENDIENTE   → Acaba de crearse, ninguna firma realizada
EN_PROCESO  → Al menos una firma completada, faltan más
COMPLETADO  → Todas las firmas requeridas fueron realizadas
```

---

## Convención de etiquetas de anclaje

En los JRXML (plantillas JasperReports), se colocan etiquetas invisibles en las celdas donde debe ir la firma:

| Etiqueta | Significado | Color |
|----------|-------------|-------|
| `[F1]` | Primer firmante (ej: SOLICITADO POR) | Blanco (`#FFFFFF`) |
| `[F2]` | Segundo firmante (ej: PREPARADO POR) | Blanco |
| `[F3]` | Tercer firmante (ej: AUTORIZADO POR) | Blanco |
| `[F1A]` / `[F1B]` | Doble estampado para un mismo firmante | Blanco |

El texto es invisible visualmente (color blanco sobre fondo blanco), pero existe en la capa de texto del PDF y PDFBox puede leerlo.

---

## Cómo iniciar el servicio

```bash
# 1. Asegurar que PostgreSQL y FirmaEC estén corriendo
cd ~/TESIS/FIRMAEC_WILDFLY_HORA && ./dev.sh up

# 2. Preparar la base de datos (primera vez)
cd ~/TESIS/word-to-jrxml/firmaService
./setup_db.sh

# 3. Iniciar firmaService
mvn spring-boot:run

# 4. Probar
./test_flujo_completo.sh
```

El servicio arranca en `http://localhost:8081`.
