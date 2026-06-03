CREATE TABLE IF NOT EXISTS publicaciones.documentos_firmables (
    id_documento_firmable BIGSERIAL PRIMARY KEY,
    id_solicitud          BIGINT,
    id_tipo_documento     BIGINT NOT NULL,
    pdf_base64            TEXT,
    nombre_archivo        VARCHAR(255),
    total_firmas_requeridas INTEGER NOT NULL DEFAULT 1,
    firmas_completadas    INTEGER NOT NULL DEFAULT 0,
    estado                VARCHAR(30) NOT NULL DEFAULT 'PENDIENTE',
    created_at            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS publicaciones.firmas_electronicas (
    id_firma_electronica  BIGSERIAL PRIMARY KEY,
    id_documento_firmable BIGINT NOT NULL
                          REFERENCES publicaciones.documentos_firmables(id_documento_firmable)
                          ON DELETE CASCADE,
    orden_firma           INTEGER NOT NULL,
    cedula_firmante       VARCHAR(15) NOT NULL,
    nombre_firmante       VARCHAR(200),
    rol_firma             VARCHAR(100),
    estado                VARCHAR(20) NOT NULL DEFAULT 'PENDIENTE',
    fecha_firma           TIMESTAMP,
    hash_firma            VARCHAR(256),
    qr_base64             TEXT,
    etiqueta_ancla        VARCHAR(10),
    coordenada_x          INTEGER,
    coordenada_y          INTEGER,
    pagina_firma          INTEGER,
    created_at            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_firma_orden UNIQUE (id_documento_firmable, orden_firma)
);

CREATE INDEX IF NOT EXISTS idx_doc_firmable_solicitud
    ON publicaciones.documentos_firmables(id_solicitud);
CREATE INDEX IF NOT EXISTS idx_doc_firmable_estado
    ON publicaciones.documentos_firmables(estado);
CREATE INDEX IF NOT EXISTS idx_firma_elec_documento
    ON publicaciones.firmas_electronicas(id_documento_firmable);
CREATE INDEX IF NOT EXISTS idx_firma_elec_cedula
    ON publicaciones.firmas_electronicas(cedula_firmante);
CREATE INDEX IF NOT EXISTS idx_firma_elec_estado
    ON publicaciones.firmas_electronicas(estado);
CREATE INDEX IF NOT EXISTS idx_firma_elec_cedula_estado
    ON publicaciones.firmas_electronicas(cedula_firmante, estado);
