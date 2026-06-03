#!/bin/bash
#
# Script centralizado para recompilar un archivo JRXML a JASPER.
#
# Uso: ./recompilar_jasper.sh [ruta_o_nombre_reporte]
# Ejemplos:
#   ./recompilar_jasper.sh comisiones/repPerOperacion.jrxml
#   ./recompilar_jasper.sh ../"4. SOLICITUD DE FONDOS"/solicitudFondos.jrxml
#   ./recompilar_jasper.sh ../"24. MTZ ORDEN DE GASTO"/ordenGasto.jrxml
#

# Obtener directorio del script
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

ARG_PATH="${1:-comisiones/repPerOperacion}"
JRXML_PATH=""

echo "╔════════════════════════════════════════════════════════════════════╗"
echo "║             RECOMPILACIÓN DE JASPER (CENTRALIZADO)                 ║"
echo "╚════════════════════════════════════════════════════════════════════╝"
echo ""

# Resolución flexible de rutas
if [ -f "$ARG_PATH" ]; then
    JRXML_PATH="$ARG_PATH"
elif [ -f "${ARG_PATH}.jrxml" ]; then
    JRXML_PATH="${ARG_PATH}.jrxml"
elif [ -f "comisiones/${ARG_PATH}" ]; then
    JRXML_PATH="comisiones/${ARG_PATH}"
elif [ -f "comisiones/${ARG_PATH}.jrxml" ]; then
    JRXML_PATH="comisiones/${ARG_PATH}.jrxml"
elif [ -f "../${ARG_PATH}" ]; then
    JRXML_PATH="../${ARG_PATH}"
elif [ -f "../${ARG_PATH}.jrxml" ]; then
    JRXML_PATH="../${ARG_PATH}.jrxml"
fi

if [ -z "$JRXML_PATH" ] || [ ! -f "$JRXML_PATH" ]; then
    echo "✗ ERROR: No se encontró el archivo JRXML para: $ARG_PATH"
    echo "Rutas intentadas:"
    echo "  - $ARG_PATH"
    echo "  - ${ARG_PATH}.jrxml"
    echo "  - comisiones/${ARG_PATH}"
    echo "  - comisiones/${ARG_PATH}.jrxml"
    echo "  - ../${ARG_PATH}"
    echo "  - ../${ARG_PATH}.jrxml"
    exit 1
fi

echo "✓ JRXML encontrado en: $JRXML_PATH"
echo ""

# Compilar CompileJasper.java si no está compilado o si cambió
if [ ! -f "CompileJasper.class" ] || [ "CompileJasper.java" -nt "CompileJasper.class" ]; then
    echo "[INFO] Compilando CompileJasper.java..."
    javac -cp ".:commons-beanutils.jar:lib/*" CompileJasper.java
    if [ $? -ne 0 ]; then
        echo "✗ ERROR: Falló la compilación de CompileJasper.java"
        exit 1
    fi
fi

# Recompilar JRXML a JASPER
echo "[PASO 1] Compilando JRXML a JASPER..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

java -Djava.awt.headless=true \
     --add-opens java.base/java.lang=ALL-UNNAMED \
     --add-opens java.base/java.util=ALL-UNNAMED \
     -cp ".:commons-beanutils.jar:lib/*" \
     CompileJasper "$JRXML_PATH"

if [ $? -ne 0 ]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "✗ ERROR CRÍTICO: Falló la compilación del reporte."
    echo "  Revisa los errores de JasperReports listados arriba."
    exit 1
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✓ JASPER compilado exitosamente en la misma ruta que el JRXML."
echo ""
echo "╔════════════════════════════════════════════════════════════════════╗"
echo "║                    ✅ COMPLETADO EXITOSAMENTE                      ║"
echo "╚════════════════════════════════════════════════════════════════════╝"
echo ""
