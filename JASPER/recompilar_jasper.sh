#!/bin/bash
#
# recompilar_jasper.sh — Compilador compatible con JR 5.x y JR 7.x
#
# Detecta automáticamente la versión del JRXML y usa el compilador correcto:
#   - JR 7.x (guardado con Jaspersoft Studio 7): usa JARs de /opt/jaspersoftstudio
#   - JR 5.x/6.x (formato antiguo):              usa lib/ del directorio actual
#
# Uso: ./recompilar_jasper.sh [ruta_o_nombre_reporte]
# Ejemplos:
#   ./recompilar_jasper.sh comisiones/repPerOperacion.jrxml
#   ./recompilar_jasper.sh "../24. MTZ ORDEN DE GASTO/ordenGasto.jrxml"
#

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

ARG_PATH="${1:-comisiones/repPerOperacion}"
JRXML_PATH=""

echo "╔════════════════════════════════════════════════════════════════════╗"
echo "║             RECOMPILACIÓN DE JASPER (JR5 + JR7 compat)            ║"
echo "╚════════════════════════════════════════════════════════════════════╝"
echo ""

# ─── Resolución flexible de rutas ────────────────────────────────────────────
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
    exit 1
fi

echo "✓ JRXML encontrado en: $JRXML_PATH"
echo ""

# ─── Detectar versión del JRXML ──────────────────────────────────────────────
IS_JR7=false
if head -3 "$JRXML_PATH" | grep -qE 'JasperReports Library version 7'; then
    IS_JR7=true
fi

# ─── Seleccionar classpath según versión ─────────────────────────────────────
STUDIO_BASE="/opt/jaspersoftstudio/configuration/org.eclipse.osgi"

if [ "$IS_JR7" = true ]; then
    echo "[INFO] Detectado formato JR 7.x — usando lib_jr6/ (JasperReports 7.0.6)"

    if [ ! -f "lib_jr6/jasperreports-7.0.6.jar" ]; then
        echo "✗ ERROR: lib_jr6/jasperreports-7.0.6.jar no encontrado."
        echo "  Los JARs de JR7 se copian automáticamente de Jaspersoft Studio."
        echo "  Verifica que /opt/jaspersoftstudio esté instalado."
        exit 1
    fi

    CP=".:lib_jr6/*"

else
    echo "[INFO] Detectado formato JR 5.x/6.x — usando compilador JR 5.1.0"
    CP=".:commons-beanutils.jar:lib/*"
fi

# ─── Compilar CompileJasper.java (siempre, para asegurar classpath correcto) ─
echo "[INFO] Compilando CompileJasper.java..."
javac -cp "$CP" CompileJasper.java -d . 2>/dev/null

# ─── Compilar JRXML → JASPER ────────────────────────────────────────────────
echo "[PASO 1] Compilando JRXML a JASPER..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

java -Djava.awt.headless=true \
     --add-opens java.base/java.lang=ALL-UNNAMED \
     --add-opens java.base/java.util=ALL-UNNAMED \
     -cp "$CP" \
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
