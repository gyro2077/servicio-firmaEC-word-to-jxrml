# SKILL: Conversión de Documento Word a Plantilla JRXML (JasperReports)

> **Objetivo:** Tomar un documento Word institucional (`.docx`) con encabezados, tablas de checklist y tablas dinámicas, y transformarlo en una plantilla `.jrxml` funcional y compilable para JasperReports, con el mismo formato visual.

---

## 1. Herramientas Necesarias

| Herramienta | Rol |
|---|---|
| `python-docx` o descompresión `.docx` | Extraer el XML interno del Word |
| Jaspersoft Studio (iReport) | Diseñar y previsualizar el `.jrxml` |
| `CompileJasper.java` + `recompilar_jasper.sh` | Compilar el `.jrxml` a `.jasper` en consola |
| `commons-beanutils.jar` + librerías JasperReports | Classpath necesario para compilar |

### Compilar y Probar en Consola
```bash
cd /home/gyro/Documents/TESIS/word-to-jrxml/JASPER

# Compilar un reporte a .jasper
./recompilar_jasper.sh ../"4. SOLICITUD DE FONDOS"/solicitudFondos.jrxml

# Compilar, rellenar y exportar a PDF para previsualización
./generar_pdf.sh ../"4. SOLICITUD DE FONDOS"/solicitudFondos.jrxml
```

---

## 2. Proceso: Extracción del Word

Un archivo `.docx` es en realidad un `.zip`. Para ver su contenido XML:

```bash
# Renombrar y descomprimir
cp MiDocumento.docx MiDocumento.zip
unzip MiDocumento.zip -d word-to-jrxml/

# Los archivos clave son:
# word-to-jrxml/word/document.xml   <- Cuerpo del documento
# word-to-jrxml/word/header1.xml    <- Encabezado (logos, título)
# word-to-jrxml/word/footer1.xml    <- Pie de página
# word-to-jrxml/word/styles.xml     <- Estilos de fuente y párrafo
# word-to-jrxml/word/media/         <- Imágenes incrustadas
```

Del `document.xml` se extraen:
- Textos de párrafos (`<w:p>`, `<w:r>`, `<w:t>`)
- Tablas (`<w:tbl>`, `<w:tr>`, `<w:tc>`)
- Formatos especiales (negrita `<w:b/>`, subrayado `<w:u/>`)

Del `header1.xml` se extrae:
- La estructura del encabezado institucional (logo, título central, cuadro de número de informe)

---

## 3. Mapeo Word → Bandas JRXML

La clave para replicar un documento Word en JasperReports es entender a qué **banda** corresponde cada sección:

| Sección del Word | Banda JRXML | Notas |
|---|---|---|
| Encabezado (logos, título) — **1ra página** | `<title>` | Debe ir al inicio de `<title>`, Y=0 |
| Encabezado (logos) — **páginas 2+** | `<pageHeader>` | Añadir `<printWhenExpression>$V{PAGE_NUMBER} > 1</printWhenExpression>` |
| Cuerpo del documento (texto, checklist) | `<title>` (continuación) | Todo el contenido estático va aquí |
| Cabeceras de la tabla dinámica | `<columnHeader>` | Se repite en cada página si hay muchas filas |
| Filas de datos dinámicos | `<detail>` | Itera sobre el resultado del `<queryString>` |
| Recomendaciones, firma, resumen | `<columnFooter>` | Aparece al final de los datos |
| Código de documento, número de página | `<pageFooter>` | Se repite en cada página |

> **Regla de Oro:** En JasperReports, el orden de impresión es:
> `title` → `pageHeader` → `columnHeader` → `detail` (repite) → `columnFooter` → `pageFooter`
> El `title` SIEMPRE se imprime antes que el `pageHeader`.

---

## 4. Construcción del Encabezado Institucional (en `<title>`)

El encabezado del Word tiene **3 columnas**: Logo | Título | Vicerrectorado + No. Informe.

Se implementa como un `<frame>` con bordes y líneas verticales:

```xml
<frame>
  <reportElement x="0" y="0" width="555" height="95" uuid="..."/>
  <box><pen lineWidth="0.5"/></box>

  <!-- Líneas divisoras verticales -->
  <line><reportElement x="110" y="0" width="1" height="95"/></line>
  <line><reportElement x="435" y="0" width="1" height="95"/></line>

  <!-- Columna 1: Logo ESPE -->
  <image>
    <reportElement x="10" y="15" width="90" height="65"/>
    <imageExpression>$P{selloSPP}.toString()</imageExpression>
  </image>

  <!-- Columna 2: Título centrado -->
  <textField>
    <reportElement x="120" y="10" width="305" height="75"/>
    <textElement textAlignment="Center" verticalAlignment="Middle">
      <font size="11" isBold="true"/>
    </textElement>
    <textFieldExpression>"INFORME DE EVALUACIÓN DE LA SOLICITUD PARA PAGO DE PUBLICACIÓN"</textFieldExpression>
  </textField>

  <!-- Columna 3: Vicerrectorado (texto pequeño) -->
  <textField>
    <reportElement x="440" y="3" width="110" height="40"/>
    <textElement textAlignment="Center"><font size="6"/></textElement>
    <textFieldExpression>"Vicerrectorado de Investigación...\nUnidad de Gestión de la Investigación"</textFieldExpression>
  </textField>

  <!-- Sub-tabla: N.° Informe (fondo amarillo) -->
  <staticText>
    <reportElement x="440" y="48" width="53" height="15"/>
    <box><pen lineWidth="0.5"/><rightPen lineWidth="0.0"/></box>
    <text>N.° Informe</text>
  </staticText>
  <textField>
    <reportElement mode="Opaque" x="493" y="48" width="62" height="15" backcolor="#FFFF00"/>
    <textFieldExpression>"VIIT-2024-036"</textFieldExpression>
  </textField>

  <!-- Sub-tabla: Página -->
  <staticText>
    <reportElement x="440" y="63" width="53" height="15"/>
    <text>Página:</text>
  </staticText>
  <textField>
    <reportElement x="493" y="63" width="62" height="15"/>
    <textFieldExpression>"1 de 1"</textFieldExpression>
  </textField>
</frame>
```

---

## 5. Texto Enriquecido (negrita, subrayado, fondo amarillo)

### Texto con HTML markup (para subrayado y negrita mixtos):
```xml
<textField isStretchWithOverflow="true">
  <reportElement x="0" y="100" width="555" height="50" positionType="Float"/>
  <textElement textAlignment="Justified" markup="html">
    <font fontName="Arial Narrow" size="10"/>
  </textElement>
  <textFieldExpression>
    "INFORME QUE PRESENTA... DRA. MARBEL TORRES ARIAS, &lt;u&gt;&lt;b&gt;PhD&lt;/b&gt;&lt;/u&gt;..."
  </textFieldExpression>
</textField>
```

### Viñeta con fondo amarillo:
```xml
<textField isStretchWithOverflow="true">
  <reportElement mode="Opaque" x="0" y="175" width="555" height="25"
                 backcolor="#FFFF00" positionType="Float"/>
  <textFieldExpression>"• Memorando ESPE-UGIN-2024-1289-M..."</textFieldExpression>
</textField>
```

---

## 6. Tabla de Checklist Estática

Cada fila del checklist es un `<frame>` independiente con 4 celdas (`staticText` o `textField`). Las columnas son:

| Columna | X | Width |
|---|---|---|
| `#` (número) | 0 | 42 |
| `Ítem` (descripción) | 42 | 246 |
| `Cumplimiento (Sí/No)` | 288 | 63 |
| `Observaciones` | 351 | 204 |
| **TOTAL** | — | **555** |

### Cabecera gris de la tabla:
```xml
<frame>
  <reportElement x="0" y="285" width="555" height="20" positionType="Float"/>
  <box><pen lineWidth="0.5"/></box>
  <staticText>
    <reportElement mode="Opaque" x="0" y="0" width="42" height="20" backcolor="#DBE5F1"/>
    <textElement textAlignment="Center" verticalAlignment="Middle"><font size="9"/></textElement>
    <text>#</text>
  </staticText>
  <!-- Repetir para Ítem, Cumplimiento, Observaciones -->
</frame>
```

### Fila de categoría (ej. "1. Requisitos de elegibilidad"):
```xml
<frame>
  <reportElement x="0" y="305" width="555" height="25" positionType="Float"/>
  <box><pen lineWidth="0.5"/></box>
  <staticText>
    <reportElement x="0" y="0" width="42" height="25"/>
    <box><pen lineWidth="0.5"/></box>
    <text>1</text>
  </staticText>
  <staticText>
    <reportElement x="42" y="0" width="246" height="25"/>
    <box><pen lineWidth="0.5"/></box>
    <text>Requisitos de elegibilidad</text>
  </staticText>
  <!-- Celdas vacías para Cumplimiento y Observaciones -->
</frame>
```

### Fila de ítem (ej. "1.1 Ser personal académico..."):
- Se usa `<textField isStretchWithOverflow="true">` en la celda de descripción para que crezca con texto largo.
- El `<frame>` padre debe tener `positionType="Float"` para que no se monte sobre el siguiente.

> **Clave:** La Y de cada `<frame>` debe ser exactamente `Y_anterior + Height_anterior`. Sin espacios.

---

## 7. Tabla Dinámica (columnHeader + detail)

Para datos que vienen de la base de datos:

```xml
<!-- Definir campos del query -->
<field name="v_apellidos" class="java.lang.String"/>
<field name="v_cedula" class="java.lang.String"/>
<!-- ... más campos ... -->

<!-- Query de prueba (reemplazar con SQL real) -->
<queryString>
  select 1 as v_numero, 'APELLIDOS Y NOMBRES' as v_apellidos,
         '1234567890' as v_cedula, 'XXX' as v_departamento,
         'TITULO DEL ARTICULO' as v_articulo, 3 as v_autor,
         'NOMBRE REVISTA' as v_revista, 'Q1' as v_impacto,
         1500.00 as v_valor
</queryString>

<!-- columnHeader: cabeceras con fondo azul claro -->
<columnHeader>
  <band height="25">
    <!-- staticText para cada columna con backcolor="#DBE5F1" -->
  </band>
</columnHeader>

<!-- detail: una fila por registro del query -->
<detail>
  <band height="25">
    <!-- textField para cada campo $F{v_apellidos}, etc. -->
  </band>
</detail>
```

---

## 8. Posicionamiento: La Regla Matemática

Para evitar solapamientos entre elementos dentro de la banda `<title>`:

```
Y del elemento N = Y del elemento (N-1) + Height del elemento (N-1)
```

**Ejemplo de orden en la banda Title:**
```
Y=0    H=95  → Frame del Encabezado (logos)
Y=100  H=50  → TextField "INFORME QUE PRESENTA..."
Y=155  H=15  → TextField "ANTECEDENTES. -"
Y=175  H=25  → TextField Memorando (fondo amarillo)
Y=200  H=75  → TextField resto de antecedentes
Y=285  H=20  → Frame cabecera tabla checklist
Y=305  H=25  → Frame fila 1 (Requisitos)
Y=330  H=35  → Frame fila 1.1
Y=365  H=25  → Frame fila 2 (Documentos requeridos)
Y=390  H=38  → Frame fila 2.1 (con observaciones largas)
... y así sucesivamente
```

Para que los textos dinámicos "empujen" a los de abajo si crecen, usar `positionType="Float"` en todos los elementos después del encabezado.

---

## 9. Pie de Página y Firma

```xml
<columnFooter>
  <band height="140">
    <!-- Recomendaciones -->
    <textField><textFieldExpression>"RECOMENDACIONES. -"</textFieldExpression></textField>
    <textField><textFieldExpression>"En base a la revisión..."</textFieldExpression></textField>

    <!-- RESUMEN centrado -->
    <textField>
      <reportElement x="200" y="45" width="155" height="15"/>
      <textElement textAlignment="Center"><font isBold="true"/></textElement>
      <textFieldExpression>"RESUMEN"</textFieldExpression>
    </textField>

    <!-- Fecha -->
    <textField>
      <reportElement x="355" y="65" width="200" height="15"/>
      <textElement textAlignment="Right"/>
      <textFieldExpression>"Sangolquí, a 1 de enero de 2025"</textFieldExpression>
    </textField>

    <!-- Línea de firma -->
    <line><reportElement x="177" y="95" width="200" height="1"/></line>
    <textField>
      <reportElement x="177" y="97" width="200" height="40"/>
      <textElement textAlignment="Center"><font isBold="true"/></textElement>
      <textFieldExpression>"Firma\nDocente de Apoyo\nUnidad de Gestión de la Investigación"</textFieldExpression>
    </textField>
  </band>
</columnFooter>

<pageFooter>
  <band height="20">
    <textField><textFieldExpression>"Código de documento: UGIN-INF-2025-V1-001"</textFieldExpression></textField>
    <textField><textFieldExpression>"Código de proceso: GINV-GATI-2"</textFieldExpression></textField>
  </band>
</pageFooter>
```

---

## 10. Checklist de Verificación Final

Antes de dar el reporte como terminado, verificar:

- [ ] **Compilación:** `./recompilar_jasper.sh nombre_reporte` no arroja errores
- [ ] **Encabezado:** Los logos aparecen en la parte superior de la primera página (`Y=0` dentro de `<title>`)
- [ ] **PageHeader vacío en pág. 1:** `<printWhenExpression>$V{PAGE_NUMBER} > 1</printWhenExpression>` correctamente añadido
- [ ] **Tabla sin huecos:** Cada fila del checklist empieza exactamente donde termina la anterior
- [ ] **Sin solapamientos:** Todos los elementos después del header tienen `positionType="Float"`
- [ ] **Texto dinámico:** Los parámetros `$P{P_NOMBRE_EVALUADOR}`, `$P{P_NOMBRE_DOCENTE}`, `$P{P_DEPARTAMENTO}` se reemplazan correctamente en Preview
- [ ] **Query de prueba:** La tabla dinámica muestra al menos 1 fila de datos de ejemplo en Preview
- [ ] **Pie de página:** El código de documento aparece en el footer de todas las páginas

---

## 11. Parámetros del Reporte

```xml
<parameter name="selloSPP" class="java.lang.String">
  <defaultValueExpression>"c:\\selloSPP.PNG"</defaultValueExpression>
</parameter>
<parameter name="P_NOMBRE_EVALUADOR" class="java.lang.String"/>
<parameter name="P_NOMBRE_DOCENTE"   class="java.lang.String"/>
<parameter name="P_DEPARTAMENTO"     class="java.lang.String"/>
```

Estos parámetros se pasan desde la aplicación Java/Payara al invocar el reporte.

---

## 12. Errores Comunes y Soluciones

| Error | Causa | Solución |
|---|---|---|
| Encabezado aparece abajo | Logos en `<pageHeader>` y texto en `<title>` | Mover logos al inicio de `<title>` (Y=0) |
| Tabla rota / con huecos | Posiciones Y no son consecutivas | Recalcular: `Y_nueva = Y_anterior + Height_anterior` |
| Elementos solapados | Posiciones Y incorrectas o sin `Float` | Revisar matemáticamente y añadir `positionType="Float"` |
| Error de compilación "element out of band" | Altura de la banda menor que el elemento más profundo | Aumentar `height` de la banda `<title>` |
| Texto cortado sin espacio | `isStretchWithOverflow` no habilitado | Añadir `isStretchWithOverflow="true"` al `textField` |

---

*Skill generada en Mayo 2026 — Proyecto TESIS ESPE — Conversión Word → JRXML*
