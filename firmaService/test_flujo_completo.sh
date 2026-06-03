#!/bin/bash
# =============================================================================
# test_flujo_completo.sh
# Test de integración del flujo completo: JRXML -> PDF -> firmaService -> FirmaEC
# =============================================================================
# Uso: ./test_flujo_completo.sh [--solo-firma] [--con-firmaservice]
#
# Opciones:
#   --solo-firma        Solo prueba firma directa contra FirmaEC (sin firmaService)
#   --con-firmaservice   Prueba el flujo completo via firmaService REST API
# =============================================================================

set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
FIRMAEC_DIR="/home/gyro/Documents/TESIS/FIRMAEC_WILDFLY_HORA"
SALIDA_DIR="$DIR/test_output"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Colores
VERDE='\033[0;32m'
ROJO='\033[0;31m'
AMARILLO='\033[1;33m'
AZUL='\033[0;34m'
NC='\033[0m'

ok()   { echo -e "${VERDE}[✓]${NC} $1"; }
fail() { echo -e "${ROJO}[✗]${NC} $1"; }
warn() { echo -e "${AMARILLO}[!]${NC} $1"; }
info() { echo -e "${AZUL}[i]${NC} $1"; }

PRUEBA_SOLO_FIRMA=false
PRUEBA_CON_FIRMASERVICE=false

for arg in "$@"; do
    case "$arg" in
        --solo-firma) PRUEBA_SOLO_FIRMA=true ;;
        --con-firmaservice) PRUEBA_CON_FIRMASERVICE=true ;;
    esac
done

if [ "$#" -eq 0 ]; then
    PRUEBA_SOLO_FIRMA=true
    PRUEBA_CON_FIRMASERVICE=true
fi

mkdir -p "$SALIDA_DIR"

echo ""
echo "╔════════════════════════════════════════════════════════════════════╗"
echo "║         TEST FLUJO COMPLETO - FIRMA ELECTRÓNICA                   ║"
echo "║         $(date)                          ║"
echo "╚════════════════════════════════════════════════════════════════════╝"
echo ""

# ===========================================================================
# 1. Verificar prerequisitos
# ===========================================================================
info "Verificando prerequisitos..."

# 1.1 FirmaEC (WildFly en :8180)
FIRMAEC_OK=false
if curl -sf -o /dev/null -w "" "http://localhost:8180/servicio/version" 2>/dev/null; then
    ok "FirmaEC disponible en localhost:8180"
    FIRMAEC_OK=true
else
    RESP=$(curl -s -o /dev/null -w "%{http_code}" -X POST \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "base64=" "http://localhost:8180/servicio/version" 2>/dev/null || echo "000")
    if [ "$RESP" != "000" ]; then
        ok "FirmaEC responde en localhost:8180 (HTTP $RESP)"
        FIRMAEC_OK=true
    else
        fail "FirmaEC NO disponible en localhost:8180. Ejecuta: ./dev.sh up"
    fi
fi

# 1.2 Docker PostgreSQL
POSTGRES_OK=false
if docker exec gestion-publicaciones-postgres psql -U postgres -d gestion_revistas -c "SELECT 1" &>/dev/null; then
    ok "PostgreSQL disponible (gestion-publicaciones-postgres:5433)"
    POSTGRES_OK=true
elif docker exec firmaec-db psql -U postgres -d gestion_revistas -c "SELECT 1" &>/dev/null; then
    ok "PostgreSQL disponible (firmaec-db:5432)"
    POSTGRES_OK=true
else
    fail "PostgreSQL NO disponible"
fi

# 1.3 Certificado .p12
CERT_PATH=""
for p in \
    "/home/gyro/Documents/Firma_Electronica/firma_1723823520.p12" \
    "/home/gyro/Documents/Firma/firma.p12" \
    "/home/gyro/Documents/FIRMA/firma_1723823520.p12"; do
    if [ -f "$p" ]; then
        CERT_PATH="$p"
        break
    fi
done

if [ -n "$CERT_PATH" ]; then
    ok "Certificado encontrado: $CERT_PATH"
else
    warn "No se encontro certificado .p12. Usa: --cert /ruta/al/cert.p12"
    read -rp "Ruta del certificado .p12: " CERT_PATH
    if [ ! -f "$CERT_PATH" ]; then
        fail "No se puede continuar sin certificado"
        exit 1
    fi
fi

# 1.4 Password
read -rsp "Password del certificado: " CERT_PASSWORD
echo ""

echo ""

# ===========================================================================
# 2. Generar PDF de prueba con anclas [F1], [F2], [F3]
# ===========================================================================
info "Generando PDF de prueba con anclas [F1][F2][F3]..."
PDF_PRUEBA="/home/gyro/Documents/TESIS/word-to-jrxml/24. MTZ ORDEN DE GASTO/ordenGasto.pdf"
if [ ! -f "$PDF_PRUEBA" ]; then
    fail "No existe el PDF base de Orden de Gasto. Compílalo primero."
    exit 1
fi

if [ ! -f "$PDF_PRUEBA" ]; then
    fail "No se pudo generar el PDF de prueba"
    exit 1
fi
# Verificar que contiene anclas
ANCLAS_ENCONTRADAS=$(pdftotext "$PDF_PRUEBA" - 2>/dev/null | grep -o '\[F[0-9]\]' | tr '\n' ' ')
if [ -n "$ANCLAS_ENCONTRADAS" ]; then
    ok "PDF listo: $(ls -lh "$PDF_PRUEBA" | awk '{print $5}') - Anclas: $ANCLAS_ENCONTRADAS"
else
    warn "PDF sin anclas [FN] detectables - la firma usara coordenadas fijas"
fi

echo ""

# ===========================================================================
# 3. PRUEBA: Firma directa contra FirmaEC
# ===========================================================================
if [ "$PRUEBA_SOLO_FIRMA" = true ] && [ "$FIRMAEC_OK" = true ]; then
    info "PRUEBA: Firma directa contra FirmaEC API..."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    API_KEY="1b6e325b1851d6f167c0a2c8e3ceb8ca727e92106992bf973b028c1bb7aff849"
    SISTEMA="test-system"
    BASE_URL="http://localhost:8180/servicio"
    PDF_SALIDA="$SALIDA_DIR/documento_firmado_directo_$TIMESTAMP.pdf"

    # Obtener JWT
    info "Obteniendo JWT..."
    JSON_PAYLOAD="{\"sistemaTransversal\":\"$SISTEMA\"}"
    BASE64_PAYLOAD=$(echo -n "$JSON_PAYLOAD" | base64 -w0)

    JWT_RESPONSE=$(curl -s -X POST \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -H "X-API-KEY: $API_KEY" \
        -d "base64=$BASE64_PAYLOAD" \
        "$BASE_URL/getjwt")

    JWT_TOKEN=$(echo "$JWT_RESPONSE" | grep -o '"response":"[^"]*"' | cut -d'"' -f4)

    if [ -z "$JWT_TOKEN" ]; then
        fail "No se pudo obtener JWT"
        echo "Respuesta: $JWT_RESPONSE"
    else
        ok "JWT obtenido correctamente"

        # Preparar datos
        DOCUMENTO_BASE64=$(base64 -w0 < "$PDF_PRUEBA")
        CERT_BASE64=$(base64 -w0 < "$CERT_PATH")
        CERT_PASSWORD_BASE64=$(echo -n "$CERT_PASSWORD" | base64 -w0)

        SYSTEM_INFO='{"sistemaOperativo":"Linux","aplicacion":"FirmaEC-Test","versionApp":"4.1.0"}'
        SYSTEM_INFO_BASE64=$(echo -n "$SYSTEM_INFO" | base64 -w0)

        # Coordenadas para [F1] (centro de la caja de SOLICITADO POR)
        JSON_CONFIG='{"versionFirmaEC":"4.1.0","formatoDocumento":"pdf","llx":"32","lly":"270","pagina":"1","tipoEstampado":"QR","razon":"Firma SOLICITADO POR - Prueba"}'

        info "Firmando PDF en coordenadas (32, 270) para [F1]..."
        FIRMA_RESPONSE=$(curl -s -X POST \
            -H "Content-Type: application/x-www-form-urlencoded" \
            --data-urlencode "jwt=$JWT_TOKEN" \
            --data-urlencode "pkcs12=$CERT_BASE64" \
            --data-urlencode "password=$CERT_PASSWORD_BASE64" \
            --data-urlencode "documento=$DOCUMENTO_BASE64" \
            --data-urlencode "json=$JSON_CONFIG" \
            --data-urlencode "base64=$SYSTEM_INFO_BASE64" \
            "$BASE_URL/appfirmardocumento")

        if echo "$FIRMA_RESPONSE" | grep -q '"docSigned"'; then
            DOCUMENTO_FIRMADO_BASE64=$(echo "$FIRMA_RESPONSE" | jq -r '.[0].docSigned')

            if [ -n "$DOCUMENTO_FIRMADO_BASE64" ] && [ "$DOCUMENTO_FIRMADO_BASE64" != "null" ]; then
                echo "$DOCUMENTO_FIRMADO_BASE64" | base64 -d > "$PDF_SALIDA"
                if file "$PDF_SALIDA" | grep -q "PDF"; then
                    ok "Firma directa exitosa! PDF: $PDF_SALIDA ($(ls -lh "$PDF_SALIDA" | awk '{print $5}'))"
                else
                    fail "El archivo generado no es un PDF valido"
                fi
            else
                warn "No se pudo extraer el documento firmado"
                echo "$FIRMA_RESPONSE" | jq .
            fi
        else
            fail "Error en firma directa"
            echo "Respuesta:" && echo "$FIRMA_RESPONSE" | jq . 2>/dev/null || echo "$FIRMA_RESPONSE" | head -5
        fi
    fi
fi

echo ""

# ===========================================================================
# 4. PRUEBA: Flujo completo via firmaService REST API
# ===========================================================================
if [ "$PRUEBA_CON_FIRMASERVICE" = true ]; then
    FIRMASERVICE_URL="http://localhost:8081/api/v1/firmas"

    info "PRUEBA: Flujo completo via firmaService REST API..."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Verificar si firmaService esta corriendo
    FS_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$FIRMASERVICE_URL/documento/1/estado" 2>/dev/null || echo "000")

    if [ "$FS_STATUS" = "000" ]; then
        warn "firmaService no esta corriendo en localhost:8081"

        if [ "$POSTGRES_OK" = false ]; then
            fail "No se puede iniciar firmaService sin PostgreSQL"
        else
            warn "Intentando iniciar firmaService..."
            info "1. Asegurate que el schema 'publicaciones' exista en PostgreSQL:"
            info "   docker exec gestion-publicaciones-postgres psql -U postgres -d gestion_revistas -c \"CREATE SCHEMA IF NOT EXISTS publicaciones;\""
            info ""
            info "2. Inicia firmaService manualmente en otra terminal:"
            info "   cd $DIR"
            info "   ./mvnw spring-boot:run"
            info "   (o usa: mvn spring-boot:run)"
            info ""
            info "3. Una vez iniciado, ejecuta este script de nuevo:"
            info "   $0 --con-firmaservice"
            echo ""
        fi
    else
        ok "firmaService disponible en localhost:8081"

        # 4.1 Crear documento firmable
        info "[4.1] Creando documento firmable..."
        PDF_BASE64=$(base64 -w0 < "$PDF_PRUEBA")

        JSON_CREAR=$(cat <<EOF
{
    "idSolicitud": 1,
    "idTipoDocumento": 1,
    "pdfBase64": "$PDF_BASE64",
    "nombreArchivo": "ordenGasto_prueba.pdf",
    "firmantes": [
        {"cedula": "1234567890", "nombre": "Ing. Juan Perez", "rol": "SOLICITADO_POR"},
        {"cedula": "0987654321", "nombre": "Ing. Maria Garcia", "rol": "PREPARADO_POR"},
        {"cedula": "1122334455", "nombre": "Ing. Carlos Lopez", "rol": "AUTORIZADO_POR"}
    ]
}
EOF
)
        DOC_RESPONSE=$(curl -s -X POST \
            -H "Content-Type: application/json" \
            -d "$JSON_CREAR" \
            "$FIRMASERVICE_URL/documento")

        DOC_ID=$(echo "$DOC_RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin).get('id',''))" 2>/dev/null || echo "")

        if [ -n "$DOC_ID" ] && [ "$DOC_ID" != "null" ]; then
            ok "Documento creado con ID: $DOC_ID"

            # 4.2 Firmar documento
            info "[4.2] Firmando documento (turno 1 - SOLICITADO POR)..."
            FIRMA_SALIDA="$SALIDA_DIR/documento_firmado_api_$TIMESTAMP.pdf"

            FIRMA_RESPONSE=$(curl -s -X POST \
                -F "cedula=1234567890" \
                -F "p12=@$CERT_PATH" \
                -F "password=$CERT_PASSWORD" \
                "$FIRMASERVICE_URL/documento/$DOC_ID/firmar")

            if echo "$FIRMA_RESPONSE" | python3 -c "import sys,json; r=json.load(sys.stdin); exit(0 if r.get('exitoso') else 1)" 2>/dev/null; then
                ok "Firma turno 1 exitosa!"

                # 4.3 Consultar estado y extraer el PDF firmado actualizado de la DB
                info "[4.3] Consultando estado del documento..."
                ESTADO_RESPONSE=$(curl -s "$FIRMASERVICE_URL/documento/$DOC_ID/estado")
                ESTADO=$(echo "$ESTADO_RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin).get('estado',''))" 2>/dev/null || echo "")
                COMPLETADAS=$(echo "$ESTADO_RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin).get('firmasCompletadas',0))" 2>/dev/null || echo "0")
                TOTAL_REQUERIDAS=$(echo "$ESTADO_RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin).get('totalFirmasRequeridas',3))" 2>/dev/null || echo "3")
                ok "Estado: $ESTADO | Firmas completadas: $COMPLETADAS/$TOTAL_REQUERIDAS"

                PDF_FIRMADO_B64=$(echo "$ESTADO_RESPONSE" | python3 -c "
import sys,json
r=json.load(sys.stdin)
d=r.get('pdfBase64')
if d:
    print(d)
" 2>/dev/null || echo "")

                if [ -n "$PDF_FIRMADO_B64" ]; then
                    echo "$PDF_FIRMADO_B64" | base64 -d > "$FIRMA_SALIDA" 2>/dev/null || true
                fi

                if [ -f "$FIRMA_SALIDA" ] && file "$FIRMA_SALIDA" | grep -q "PDF"; then
                    ok "PDF firmado guardado: $FIRMA_SALIDA ($(ls -lh "$FIRMA_SALIDA" | awk '{print $5}'))"
                fi
            else
                fail "Error en firma turno 1"
                echo "Respuesta: $FIRMA_RESPONSE"
            fi
        else
            fail "No se pudo crear el documento"
            echo "Respuesta: $(echo "$DOC_RESPONSE" | head -5)"
        fi
    fi
fi

echo ""
echo "╔════════════════════════════════════════════════════════════════════╗"
echo "║                     RESUMEN DE LA PRUEBA                          ║"
echo "╚════════════════════════════════════════════════════════════════════╝"
echo ""
echo "  Directorio de salida: $SALIDA_DIR"
echo "  Archivos generados:"
ls -lh "$SALIDA_DIR/" 2>/dev/null | grep "$TIMESTAMP" | awk '{printf "    %s (%s)\n", $NF, $5}'
echo ""
echo "  Para verificar las anclas en el PDF (texto invisible):"
echo "    pdftotext \"$PDF_PRUEBA\" - | grep -o '\\[F[0-9]\\]'"
echo ""
echo "╚════════════════════════════════════════════════════════════════════╝"
