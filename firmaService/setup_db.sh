#!/bin/bash
# =============================================================================
# setup_db.sh - Prepara la base de datos para firmaService
# Crea el schema publicaciones y ejecuta la migracion Flyway manualmente
# =============================================================================
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
DB_CONTAINER="gestion-publicaciones-postgres"

echo "╔════════════════════════════════════════════════════════════════════╗"
echo "║         SETUP BASE DE DATOS - firmaService                        ║"
echo "╚════════════════════════════════════════════════════════════════════╝"

# Verificar container
if ! docker ps --format "{{.Names}}" | grep -q "$DB_CONTAINER"; then
    echo "✗ Container $DB_CONTAINER no encontrado"
    echo "  Containers disponibles:"
    docker ps --format "  {{.Names}} ({{.Ports}})"
    exit 1
fi

echo "✓ Container $DB_CONTAINER encontrado"

# Crear schema
echo ""
echo "[1/3] Creando schema 'publicaciones'..."
docker exec "$DB_CONTAINER" psql -U postgres -d gestion_revistas -c "CREATE SCHEMA IF NOT EXISTS publicaciones;"
echo "  ✓ Schema 'publicaciones' listo"

# Ejecutar migracion Flyway manualmente
echo ""
echo "[2/3] Ejecutando migracion Flyway..."
MIGRATION_FILE="$DIR/src/main/resources/db/migration/V1__init_schema_firmas.sql"

if [ -f "$MIGRATION_FILE" ]; then
    docker exec -i "$DB_CONTAINER" psql -U postgres -d gestion_revistas < "$MIGRATION_FILE"
    echo "  ✓ Migracion ejecutada"
else
    echo "  ✗ No se encontro $MIGRATION_FILE"
    exit 1
fi

# Verificar tablas
echo ""
echo "[3/3] Verificando tablas creadas..."
docker exec "$DB_CONTAINER" psql -U postgres -d gestion_revistas -c "\dt publicaciones.*"

echo ""
echo "╔════════════════════════════════════════════════════════════════════╗"
echo "║           ✅ BASE DE DATOS LISTA PARA firmaService                 ║"
echo "╚════════════════════════════════════════════════════════════════════╝"
echo ""
echo "Para iniciar firmaService:"
echo "  cd $DIR"
echo "  mvn spring-boot:run"
echo ""
echo "Para pruebas:"
echo "  ./test_flujo_completo.sh --solo-firma     (prueba firma directa)"
echo "  ./test_flujo_completo.sh --con-firmaservice (prueba via REST API)"
