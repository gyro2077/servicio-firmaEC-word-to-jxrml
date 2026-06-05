#!/bin/bash
# =============================================================================
# test_flujo_completo.sh
# Test de integración del flujo completo de 3 firmas sobre ordenGasto.pdf
# =============================================================================
# Uso:
#   ./test_flujo_completo.sh              # Menú interactivo
#   ./test_flujo_completo.sh --solo-firma  # Firma directa contra FirmaEC
#   ./test_flujo_completo.sh --con-firmaservice   # Loop 3 turnos via REST API
# =============================================================================

set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
SALIDA_DIR="$DIR/test_output"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# ============ PARSEO DE ARGUMENTOS ============
PDF_BASE=""
MODO=""
REANUDAR_DOC_ID=""
REANUDAR_TURNO=""

while [ $# -gt 0 ]; do
  case "$1" in
    --solo-firma)
      MODO="solo-firma"
      shift
      ;;
    --con-firmaservice)
      MODO="con-firmaservice"
      shift
      ;;
    --reanudar)
      MODO="reanudar"
      if [ -n "${2:-}" ] && [ -n "${3:-}" ]; then
        REANUDAR_DOC_ID="$2"
        REANUDAR_TURNO="$3"
        shift 3
      else
        echo "Error: --reanudar requiere <DOC_ID> y <TURNO>"
        exit 1
      fi
      ;;
    -*)
      echo "Opción desconocida: $1"
      echo "Uso: $0 [ruta_al_pdf] [--solo-firma | --con-firmaservice | --reanudar <doc_id> <turno>]"
      exit 1
      ;;
    *)
      if [ -z "$PDF_BASE" ]; then
        PDF_BASE="$1"
      else
        echo "Error: Argumento no esperado o PDF duplicado: $1"
        exit 1
      fi
      shift
      ;;
  esac
done

if [ -z "$PDF_BASE" ]; then
  PDF_BASE="/home/gyro/Documents/TESIS/word-to-jrxml/24. MTZ ORDEN DE GASTO/ordenGasto.pdf"
fi

if [ -z "$MODO" ]; then
  MODO="con-firmaservice"
fi

# Colores
VERDE='\033[0;32m'; ROJO='\033[0;31m'; AMARILLO='\033[1;33m'
AZUL='\033[0;34m'; MAGENTA='\033[0;35m'; CYAN='\033[0;36m'; NC='\033[0m'

ok()    { echo -e "${VERDE}[✓]${NC} $1"; }
fail()  { echo -e "${ROJO}[✗]${NC} $1"; }
warn()  { echo -e "${AMARILLO}[!]${NC} $1"; }
info()  { echo -e "${AZUL}[i]${NC} $1"; }
tit()   { echo -e "${MAGENTA}━━━ $1 ━━━${NC}"; }

# ============ CONFIG ============
FIRMASERVICE_URL="http://localhost:8081/api/v1/firmas"
DB_CONTAINER="gestion-publicaciones-postgres"
DB_NAME="gestion_revistas"
DB_USER="postgres"

# Firmantes registrados (3 turnos)
TURNOS=(
  "1234567890:SOLICITADO_POR:Ing. Juan Perez"
  "0987654321:PREPARADO_POR:Ing. Maria Garcia"
  "1122334455:AUTORIZADO_POR:Ing. Carlos Lopez"
)

# ============ FUNCIONES ============

verificar_db() {
  local doc_id="$1"
  local turno="$2"
  info "Estado en BD tras turno $turno:"
  docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -At \
    -c "SELECT firmas_completadas, total_firmas_requeridas, estado FROM publicaciones.documentos_firmables WHERE id_documento_firmable=$doc_id;" 2>/dev/null || true
  docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -At \
    -c "SELECT orden_firma, cedula_firmante, rol_firma, estado, COALESCE(fecha_firma::text,'---') FROM publicaciones.firmas_electronicas WHERE id_documento_firmable=$doc_id ORDER BY orden_firma;" 2>/dev/null || true
}

mostrar_estado_db() {
  local doc_id="$1"
  echo ""
  IFS='|' read -r completadas total estado <<< \
    "$(docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -At -c "SELECT firmas_completadas, total_firmas_requeridas, estado FROM publicaciones.documentos_firmables WHERE id_documento_firmable=$doc_id;")"
  echo "  ┌─────────────────────────────────────────────────────┐"
  printf "  │ %-20s │ %-25s │\n" "Documento" "ID: $doc_id"
  printf "  │ %-20s │ %-25s │\n" "Estado" "$estado"
  printf "  │ %-20s │ %-25s │\n" "Firmas" "$completadas / $total"
  echo "  └─────────────────────────────────────────────────────┘"
  echo "  Firmas detalle:"
  echo "  Orden | Cédula        | Rol               | Estado    | Fecha"
  echo "  ──────┼───────────────┼───────────────────┼───────────┼────────────"
  docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -t -A -F'|' \
    -c "SELECT orden_firma, cedula_firmante, rol_firma, estado, COALESCE(to_char(fecha_firma,'HH24:MI DD/MM'),'---') FROM publicaciones.firmas_electronicas WHERE id_documento_firmable=$doc_id ORDER BY orden_firma;" 2>/dev/null | \
    while IFS='|' read -r ord ced rol est fec; do
      printf "  %-5s | %-13s | %-17s | %-9s | %s\n" "$ord" "$ced" "$rol" "$est" "$fec"
    done
  echo ""
}

descargar_pdf() {
  local doc_id="$1"
  local turno="$2"
  local pdf_name
  pdf_name=$(basename "$PDF_BASE" .pdf)
  local archivo="$SALIDA_DIR/${pdf_name}_turno${turno}_${TIMESTAMP}.pdf"
  local b64
  b64=$(curl -s "$FIRMASERVICE_URL/documento/$doc_id/estado" | python3 -c "
import sys, json
r = json.load(sys.stdin)
d = r.get('pdfBase64', '')
print(d)
" 2>/dev/null)
  if [ -n "$b64" ]; then
    echo "$b64" | base64 -d > "$archivo" 2>/dev/null
    if file "$archivo" 2>/dev/null | grep -q "PDF"; then
      ok "PDF turno $turno: $(ls -lh "$archivo" | awk '{print $5}')"
    fi
  fi
}

firmar_turno() {
  local doc_id="$1"
  local turno="$2"
  local cedula="$3"
  local nombre="$4"
  local ancla="$5"

  echo ""
  tit "Turno $turno — $nombre (ancla $ancla)"
  echo "  Cédula: $cedula"
  echo "  Certificado: $(basename "$CERT_PATH")"

  local respuesta
  respuesta=$(curl -s -X POST \
    -F "cedula=$cedula" \
    -F "p12=@$CERT_PATH" \
    -F "password=$CERT_PASSWORD" \
    "$FIRMASERVICE_URL/documento/$doc_id/firmar")

  local exitoso
  exitoso=$(echo "$respuesta" | python3 -c "
import sys, json
r = json.load(sys.stdin)
print(r.get('exitoso', 'False'))
" 2>/dev/null)

  if [ "$exitoso" = "True" ]; then
    ok "Firma turno $turno exitosa!"
    mostrar_estado_db "$doc_id"
    descargar_pdf "$doc_id" "$turno"
    return 0
  else
    local error
    error=$(echo "$respuesta" | python3 -c "
import sys, json
r = json.load(sys.stdin)
print(r.get('mensajeError', 'Error desconocido'))
" 2>/dev/null)
    fail "Error firma turno $turno: $error"
    echo "  Debug: $(echo "$respuesta" | python3 -m json.tool 2>/dev/null | head -10)"
    return 1
  fi
}

menu_cedulas() {
  echo ""
  echo "╔═══════════════════════════════════════════════════════════════╗"
  echo "║          CONFIGURACIÓN DE CÉDULAS PARA LOS 3 TURNOS          ║"
  echo "╚═══════════════════════════════════════════════════════════════╝"
  echo ""
  echo "Tienes 3 firmantes registrados. ¿Qué cédulas usar?"
  echo ""
  echo "  [1] Usar las 3 cédulas ficticias (recomendado)"
  echo "      Turno 1: 1234567890 (SOLICITADO_POR)"
  echo "      Turno 2: 0987654321 (PREPARADO_POR)"
  echo "      Turno 3: 1122334455 (AUTORIZADO_POR)"
  echo "      → El backend NO valida que la cédula del .p12 coincida"
  echo ""
  echo "  [2] Usar tu cédula real para los 3 turnos"
  echo "      (el mismo .p12 firma en las 3 anclas distintas)"
  echo ""
  read -rp "Selecciona [1/2] (default 1): " CED_OPCION
  CED_OPCION=${CED_OPCION:-1}
  echo ""

  if [ "$CED_OPCION" = "2" ]; then
    read -rp "Ingresa tu cédula real: " CEDULA_REAL
    # Reemplazar cédulas en los turnos
    TURNOS_MOD=()
    for t in "${TURNOS[@]}"; do
      IFS=':' read -r _ rol nombre <<< "$t"
      TURNOS_MOD+=("${CEDULA_REAL}:${rol}:${nombre}")
    done
    TURNOS=("${TURNOS_MOD[@]}")
    ok "Usando cédula $CEDULA_REAL para los 3 turnos"
  else
    ok "Usando cédulas ficticias (3 turnos distintos)"
  fi
}

# ============ MAIN ============
mkdir -p "$SALIDA_DIR"

PDF_NAME=$(basename "$PDF_BASE")
PDF_NAME_NO_EXT=$(basename "$PDF_BASE" .pdf)

echo ""
echo "╔════════════════════════════════════════════════════════════════════╗"
printf "║    TEST 3 FIRMAS — %-47s ║\n" "$PDF_NAME"
printf "║    %-63s ║\n" "$(date)"
echo "╚════════════════════════════════════════════════════════════════════╝"
echo ""

# 1. PRERREQUISITOS
info "Verificando prerequisitos..."

FIRMAEC_OK=false
if curl -s -o /dev/null -w "" -X POST -H "Content-Type: application/x-www-form-urlencoded" \
  -d "base64=" "http://localhost:8180/servicio/version" 2>/dev/null; then
  ok "FirmaEC disponible en localhost:8180"; FIRMAEC_OK=true
else
  fail "FirmaEC NO disponible. Ejecuta: cd ~/TESIS/FIRMAEC_WILDFLY_HORA && ./dev.sh up"; FIRMAEC_OK=false
fi

POSTGRES_OK=false
if docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1" &>/dev/null; then
  ok "PostgreSQL disponible ($DB_CONTAINER:$DB_NAME)"; POSTGRES_OK=true
else
  fail "PostgreSQL NO disponible"; POSTGRES_OK=false
fi

CERT_PATH=""
for p in \
  "/home/gyro/Documents/Firma_Electronica/firma_1723823520.p12" \
  "/home/gyro/Documents/Firma/firma.p12" \
  "/home/gyro/Documents/FIRMA/firma_1723823520.p12"; do
  [ -f "$p" ] && { CERT_PATH="$p"; break; }
done

if [ -z "$CERT_PATH" ]; then
  read -rp "Ruta del certificado .p12: " CERT_PATH
  [ ! -f "$CERT_PATH" ] && { fail "No existe el certificado"; exit 1; }
fi
ok "Certificado: $(basename "$CERT_PATH")"

read -rsp "Password del certificado: " CERT_PASSWORD
echo ""; echo ""

# 2. PDF
if [ ! -f "$PDF_BASE" ]; then
  fail "No existe $PDF_BASE. Genera el PDF primero."
  exit 1
fi
ANCLAS=$(pdftotext "$PDF_BASE" - 2>/dev/null | grep -o '\[F[0-9]\]' | tr '\n' ' ')
if [ -n "$ANCLAS" ]; then
  ok "PDF base: $(ls -lh "$PDF_BASE" | awk '{print $5}') — Anclas: $ANCLAS"
else
  warn "PDF sin anclas detectables — se usarán coordenadas fijas"
fi
echo ""

# 3. MODO: SOLO FIRMA DIRECTA
if [ "$MODO" = "solo-firma" ] && [ "$FIRMAEC_OK" = true ]; then
  tit "FIRMA DIRECTA CONTRA FIRMAEC"
  API_KEY="1b6e325b1851d6f167c0a2c8e3ceb8ca727e92106992bf973b028c1bb7aff849"
  SYS="test-system"
  JWT=$(curl -s -X POST -H "Content-Type: application/x-www-form-urlencoded" \
    -H "X-API-KEY: $API_KEY" \
    -d "base64=$(echo -n "{\"sistemaTransversal\":\"$SYS\"}" | base64 -w0)" \
    "http://localhost:8180/servicio/getjwt" | grep -o '"response":"[^"]*"' | cut -d'"' -f4)
  [ -n "$JWT" ] && ok "JWT obtenido" || { fail "JWT falló"; exit 1; }
  DOC_B64=$(base64 -w0 < "$PDF_BASE")
  CERT_B64=$(base64 -w0 < "$CERT_PATH")
  PASS_B64=$(echo -n "$CERT_PASSWORD" | base64 -w0)
  SYS_B64=$(echo -n '{"sistemaOperativo":"Linux","aplicacion":"FirmaEC-Test","versionApp":"4.1.0"}' | base64 -w0)
  JSON_CFG='{"versionFirmaEC":"4.1.0","formatoDocumento":"pdf","llx":"32","lly":"270","pagina":"1","tipoEstampado":"QR","razon":"Firma directa - Prueba"}'
  RESP=$(curl -s -X POST -H "Content-Type: application/x-www-form-urlencoded" \
    --data-urlencode "jwt=$JWT" \
    --data-urlencode "pkcs12=$CERT_B64" \
    --data-urlencode "password=$PASS_B64" \
    --data-urlencode "documento=$DOC_B64" \
    --data-urlencode "json=$JSON_CFG" \
    --data-urlencode "base64=$SYS_B64" \
    "http://localhost:8180/servicio/appfirmardocumento")
  PDF_B64=$(echo "$RESP" | jq -r '.[0].docSigned' 2>/dev/null)
  if [ -n "$PDF_B64" ] && [ "$PDF_B64" != "null" ]; then
    echo "$PDF_B64" | base64 -d > "$SALIDA_DIR/firma_directa_$TIMESTAMP.pdf"
    ok "PDF firmado: $SALIDA_DIR/firma_directa_$TIMESTAMP.pdf"
  else
    fail "Error en firma directa: $(echo "$RESP" | head -3)"
  fi
  exit 0
fi

# 4. MODO: REANUDAR
if [ "$MODO" = "reanudar" ]; then
  # Check if we have DOC_ID and TURNO
  if [ -z "$REANUDAR_DOC_ID" ] || [ -z "$REANUDAR_TURNO" ]; then
    fail "Falta DOC_ID o TURNO para reanudar."
    exit 1
  fi
  DOC_ID="$REANUDAR_DOC_ID"
  
  # Menú de cédulas
  menu_cedulas
  
  # Iniciar loop desde el turno indicado
  START_INDEX=$((REANUDAR_TURNO - 1))
  for ((i=START_INDEX; i<3; i++)); do
    IFS=':' read -r CEDULA ROL NOMBRE <<< "${TURNOS[$i]}"
    TURNO=$((i + 1))
    ANCLA="[F$TURNO]"

    firmar_turno "$DOC_ID" "$TURNO" "$CEDULA" "$NOMBRE" "$ANCLA" || {
      warn "Fallo en turno $TURNO. Puedes reintentar con:"
      echo "  $0 \"$PDF_BASE\" --reanudar $DOC_ID $TURNO"
      break
    }
  done
  
  # Resultado final
  tit "RESULTADO FINAL (REANUDACIÓN)"
  mostrar_estado_db "$DOC_ID"
  echo ""
  echo "  Archivos en: $SALIDA_DIR"
  ls -lh "$SALIDA_DIR"/"${PDF_NAME_NO_EXT}"_turno*_"$TIMESTAMP".pdf 2>/dev/null | \
    awk '{printf "    %s (%s)\n", $NF, $5}'
  echo ""
  ok "Proceso completado. Revisa los PDFs en $SALIDA_DIR"
  exit 0
fi

# 5. MODO: FIRMASERVICE (3 TURNOS)
if [ "$MODO" = "con-firmaservice" ]; then
  # Check firmaService
  FS_OK=$(curl -s -o /dev/null -w "%{http_code}" "$FIRMASERVICE_URL/documento/1/estado" 2>/dev/null || echo "000")
  if [ "$FS_OK" = "000" ]; then
    fail "firmaService no está corriendo en localhost:8081"
    echo ""
    echo "  Inicia firmaService en otra terminal:"
    echo "    cd $DIR && mvn spring-boot:run"
    echo ""
    echo "  Luego vuelve a ejecutar:"
    echo "    $0 \"$PDF_BASE\" --con-firmaservice"
    exit 1
  fi
  ok "firmaService disponible en localhost:8081"

  # Menú de cédulas
  menu_cedulas

  # Crear documento
  tit "CREANDO DOCUMENTO EN DB"
  PDF_B64=$(base64 -w0 < "$PDF_BASE")

  # Construir JSON de firmantes
  FIRMANTES_JSON=""
  for t in "${TURNOS[@]}"; do
    IFS=':' read -r cedula rol nombre <<< "$t"
    [ -n "$FIRMANTES_JSON" ] && FIRMANTES_JSON+=","
    FIRMANTES_JSON+="{\"cedula\":\"$cedula\",\"nombre\":\"$nombre\",\"rol\":\"$rol\"}"
  done

  JSON_CREAR="{\"idSolicitud\":1,\"idTipoDocumento\":1,\"pdfBase64\":\"$PDF_B64\",\"nombreArchivo\":\"$PDF_NAME\",\"firmantes\":[$FIRMANTES_JSON]}"

  DOC_RESP=$(curl -s -X POST -H "Content-Type: application/json" -d "$JSON_CREAR" "$FIRMASERVICE_URL/documento")
  DOC_ID=$(echo "$DOC_RESP" | python3 -c "import sys,json; print(json.load(sys.stdin).get('id',''))" 2>/dev/null || echo "")

  if [ -z "$DOC_ID" ] || [ "$DOC_ID" = "null" ]; then
    fail "No se pudo crear el documento"
    echo "$DOC_RESP" | python3 -m json.tool 2>/dev/null | head -10
    exit 1
  fi
  ok "Documento creado con ID: $DOC_ID"
  echo ""

  # Loop de 3 turnos
  for i in 0 1 2; do
    IFS=':' read -r CEDULA ROL NOMBRE <<< "${TURNOS[$i]}"
    TURNO=$((i + 1))
    ANCLA="[F$TURNO]"

    firmar_turno "$DOC_ID" "$TURNO" "$CEDULA" "$NOMBRE" "$ANCLA" || {
      warn "Fallo en turno $TURNO. Puedes reintentar con:"
      echo "  $0 \"$PDF_BASE\" --reanudar $DOC_ID $TURNO"
      break
    }
  done

  # Resultado final
  tit "RESULTADO FINAL"
  mostrar_estado_db "$DOC_ID"
  echo ""
  echo "  Archivos en: $SALIDA_DIR"
  ls -lh "$SALIDA_DIR"/"${PDF_NAME_NO_EXT}"_turno*_"$TIMESTAMP".pdf 2>/dev/null | \
    awk '{printf "    %s (%s)\n", $NF, $5}'
  echo ""
  ok "Proceso completado. Revisa los PDFs en $SALIDA_DIR"
fi
