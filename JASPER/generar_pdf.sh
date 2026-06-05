#!/bin/bash
#
# Script centralizado para rellenar un reporte Jasper y exportarlo a PDF con datos simulados.
#
# Uso: ./generar_pdf.sh <ruta_reporte.jasper_o_jrxml> [ruta_salida.pdf]
# Ejemplos:
#   ./generar_pdf.sh ../"4. SOLICITUD DE FONDOS"/solicitudFondos.jrxml
#   ./generar_pdf.sh ../"24. MTZ ORDEN DE GASTO"/ordenGasto.jasper
#

# Obtener directorio del script
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

ARG_PATH="$1"
OUT_PDF_PATH="$2"

echo "╔════════════════════════════════════════════════════════════════════╗"
echo "║             GENERACIÓN DE PDF LOCAL (CENTRALIZADA)                 ║"
echo "╚════════════════════════════════════════════════════════════════════╝"
echo ""

if [ -z "$ARG_PATH" ]; then
    echo "Uso: $0 <ruta_reporte.jasper_o_jrxml> [ruta_salida.pdf]"
    exit 1
fi

# Resolución flexible de rutas
TARGET_PATH=""
if [ -f "$ARG_PATH" ]; then
    TARGET_PATH="$ARG_PATH"
elif [ -f "${ARG_PATH}.jrxml" ]; then
    TARGET_PATH="${ARG_PATH}.jrxml"
elif [ -f "${ARG_PATH}.jasper" ]; then
    TARGET_PATH="${ARG_PATH}.jasper"
elif [ -f "comisiones/${ARG_PATH}" ]; then
    TARGET_PATH="comisiones/${ARG_PATH}"
elif [ -f "comisiones/${ARG_PATH}.jrxml" ]; then
    TARGET_PATH="comisiones/${ARG_PATH}.jrxml"
elif [ -f "comisiones/${ARG_PATH}.jasper" ]; then
    TARGET_PATH="comisiones/${ARG_PATH}.jasper"
elif [ -f "../${ARG_PATH}" ]; then
    TARGET_PATH="../${ARG_PATH}"
elif [ -f "../${ARG_PATH}.jrxml" ]; then
    TARGET_PATH="../${ARG_PATH}.jrxml"
elif [ -f "../${ARG_PATH}.jasper" ]; then
    TARGET_PATH="../${ARG_PATH}.jasper"
fi

if [ -z "$TARGET_PATH" ] || [ ! -f "$TARGET_PATH" ]; then
    echo "✗ ERROR: No se encontró el reporte para: $ARG_PATH"
    exit 1
fi

# Si es un .jrxml, recompilarlo primero
if [[ "$TARGET_PATH" == *.jrxml ]]; then
    echo "[INFO] Se especificó un archivo .jrxml. Recompilando primero..."
    ./recompilar_jasper.sh "$TARGET_PATH"
    if [ $? -ne 0 ]; then
        echo "✗ ERROR: Falló la compilación preliminar del .jrxml"
        exit 1
    fi
    JASPER_PATH="${TARGET_PATH%.jrxml}.jasper"
else
    JASPER_PATH="$TARGET_PATH"
fi

if [ ! -f "$JASPER_PATH" ]; then
    echo "✗ ERROR: No existe el archivo compilado .jasper: $JASPER_PATH"
    exit 1
fi

# Determinar ruta del PDF de salida si no se especificó
if [ -z "$OUT_PDF_PATH" ]; then
    OUT_PDF_PATH="${JASPER_PATH%.jasper}.pdf"
fi

# ─── Detectar versión del .jasper para elegir classpath correcto ─────────────
# Buscamos el .jrxml compañero del .jasper para leer su versión
JRXML_COMPANION="${JASPER_PATH%.jasper}.jrxml"
IS_JR7=false
if [ -f "$JRXML_COMPANION" ]; then
    if head -3 "$JRXML_COMPANION" | grep -qE 'JasperReports Library version 7'; then
        IS_JR7=true
    fi
fi

if [ "$IS_JR7" = true ]; then
    echo "[INFO] Detectado .jasper compilado con JR 7.x — usando lib_jr6/"
    CP=".:lib_jr6/*"
else
    echo "[INFO] Detectado .jasper compilado con JR 5.x — usando lib/"
    CP=".:commons-beanutils.jar:lib/*"
fi

# Asegurarse de que ExportPDF está compilado con el classpath correcto
echo "[INFO] Compilando ExportPDF.java..."
javac -cp "$CP" ExportPDF.java
if [ $? -ne 0 ]; then
    echo "✗ ERROR: Falló la compilación de ExportPDF.java"
    exit 1
fi

# Generar PDF
echo "[PASO 2] Rellenando reporte y exportando a PDF..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

java -Djava.awt.headless=true \
     --add-opens java.base/java.lang=ALL-UNNAMED \
     --add-opens java.base/java.util=ALL-UNNAMED \
     -cp "$CP" \
     ExportPDF "$JASPER_PATH" "$OUT_PDF_PATH"

if [ $? -ne 0 ]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "✗ ERROR CRÍTICO: Falló la generación del PDF."
    exit 1
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✓ PDF generado exitosamente en: $OUT_PDF_PATH"
echo ""
echo "╔════════════════════════════════════════════════════════════════════╗"
echo "║                    ✅ COMPLETADO EXITOSAMENTE                      ║"
echo "╚════════════════════════════════════════════════════════════════════╝"
echo ""
