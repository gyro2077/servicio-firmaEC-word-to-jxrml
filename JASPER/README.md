# 📋 Entorno Centralizado de JasperReports — Guía de Compilación y Pruebas

Este directorio contiene todo el entorno necesario para compilar archivos `.jrxml` de JasperReports y exportar archivos `.pdf` de prueba de manera autónoma, sin depender de otros proyectos o directorios externos.

---

## 📁 Estructura del Directorio `JASPER`

Todo lo requerido está empaquetado en este directorio:

```
JASPER/
├── lib/                         ← Las 30 dependencias (.jar) del motor de reportes
├── comisiones/                  ← Carpeta de reportes y recursos institucionales (.jrxml, .png, etc.)
├── README.md                    ← Este archivo de instrucciones
├── SKILL_word_to_jrxml.md       ← Guía técnica para convertir Word a JRXML
├── SKILL_xlsx_to_jrxml.md       ← Guía técnica para convertir Excel (XLSX) a JRXML
├── CompileJasper.java / .class  ← Herramienta interna para compilar JRXML a JASPER
├── ExportPDF.java / .class      ← Herramienta interna para rellenar reportes y generar PDFs
├── recompilar_jasper.sh         ← Script de consola para compilar reportes
└── generar_pdf.sh               ← Script de consola para compilar, rellenar y exportar a PDF
```

---

## 🚀 Uso de Scripts de Automatización

Ambos scripts soportan **resolución flexible de rutas**, por lo que puedes llamarlos pasando una ruta relativa o absoluta al archivo.

### 1. Recompilar JRXML a JASPER
Este script compila el archivo XML del reporte (`.jrxml`) generando el binario ejecutable (`.jasper`) en la misma ubicación del archivo original.

```bash
cd /home/gyro/Documents/TESIS/word-to-jrxml/JASPER

# Ejemplos de uso:
# 1. Compilar un reporte en la carpeta comisiones/ (por defecto repPerOperacion si no se pasa argumento)
./recompilar_jasper.sh comisiones/repPerOperacion.jrxml

# 2. Compilar un reporte de la carpeta de Word en un subdirectorio superior
./recompilar_jasper.sh ../"4. SOLICITUD DE FONDOS"/solicitudFondos.jrxml

# 3. Compilar un reporte de la carpeta de Excel en un subdirectorio superior
./recompilar_jasper.sh ../"24. MTZ ORDEN DE GASTO"/ordenGasto.jrxml
```

---

### 2. Generar PDF de Pruebas
Este script te permite llenar el reporte con una estructura de datos vacía y parámetros por defecto, exportándolo directamente a PDF para previsualizar el diseño en segundos.
*Si el archivo que le pasas termina en `.jrxml`, el script lo compilará automáticamente a `.jasper` antes de generar el PDF.*

```bash
cd /home/gyro/Documents/TESIS/word-to-jrxml/JASPER

# Ejemplos de uso:
# 1. Generar PDF a partir de un .jrxml directo (compila y exporta)
./generar_pdf.sh ../"4. SOLICITUD DE FONDOS"/solicitudFondos.jrxml

# 2. Generar PDF a partir de un .jasper precompilado
./generar_pdf.sh ../"24. MTZ ORDEN DE GASTO"/ordenGasto.jasper

# 3. Generar PDF especificando una ruta de salida personalizada
./generar_pdf.sh ../"24. MTZ ORDEN DE GASTO"/ordenGasto.jrxml /home/gyro/Desktop/test_orden.pdf
```

---

## 🔧 Detalles Técnicos y Compatibilidad con Java 21

El sistema operativo del usuario utiliza **OpenJDK 21**. Debido a las restricciones de modularidad introducidas en las versiones modernas de Java, el motor de JasperReports (que utiliza reflexión y Groovy) requiere abrir los paquetes del sistema.

Ambos scripts incluyen las siguientes banderas necesarias para evitar errores de tipo `IllegalAccessException` o de seguridad de reflexión:
```bash
java --add-opens java.base/java.lang=ALL-UNNAMED \
     --add-opens java.base/java.util=ALL-UNNAMED \
     -cp ".:commons-beanutils.jar:lib/*" \
     ...
```

Si necesitas compilar manualmente las utilidades Java, hazlo con el classpath local:
```bash
# Compilar utilidades
javac -cp ".:commons-beanutils.jar:lib/*" CompileJasper.java
javac -cp ".:commons-beanutils.jar:lib/*" ExportPDF.java
```

---

## 📚 Habilidades del Desarrollador (Skills)

Para comprender las mejores prácticas y los bloques de diseño XML específicos para cada tipo de conversión, consulta los siguientes manuales interactivos en este mismo directorio:

* **[Guía Word a JRXML](file:///home/gyro/Documents/TESIS/word-to-jrxml/JASPER/SKILL_word_to_jrxml.md)**: Mapeo de secciones estáticas, frames para el encabezado de doble logo, tablas estáticas de checklist y manejo de saltos de página con encabezados en páginas 2+.
* **[Guía Excel a JRXML](file:///home/gyro/Documents/TESIS/word-to-jrxml/JASPER/SKILL_xlsx_to_jrxml.md)**: Grid horizontal (Landscape), presupuestos exactos de anchos de columna para evitar recortes, alineación perfecta de filas de totales y dimensionamiento de cuadros de firmas para firmas electrónicas.

---

*Proyecto de Tesis — ESPE — Mayo 2026*
