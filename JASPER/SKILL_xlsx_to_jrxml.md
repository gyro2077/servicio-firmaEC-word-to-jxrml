# SKILL: Conversión de Hojas Excel (XLSX) a Plantillas JRXML (JasperReports)

> **Objetivo:** Tomar una matriz o documento estructurado en Excel (`.xlsx`), generalmente de formato ancho u horizontal (Landscape), y transformarlo en una plantilla `.jrxml` de JasperReports que conserve perfectamente la estructura de rejilla, anchos de columna, alineación de totales y cajas amplias para firmas electrónicas.

---

## 1. Configuración de la Página Horizontal (Landscape)

Los documentos basados en Excel suelen tener múltiples columnas y requieren una orientación horizontal. En JasperReports, esto se define utilizando el estándar **A4 Landscape**.

### Parámetros de Página en el JRXML:
```xml
<jasperReport xmlns="http://jasperreports.sourceforge.net/jasperreports" 
              xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
              xsi:schemaLocation="http://jasperreports.sourceforge.net/jasperreports http://jasperreports.sourceforge.net/xsd/jasperreport.xsd" 
              name="ordenGasto" 
              language="groovy" 
              pageWidth="842" 
              pageHeight="595" 
              orientation="Landscape" 
              columnWidth="802" 
              leftMargin="20" 
              rightMargin="20" 
              topMargin="20" 
              bottomMargin="20" 
              isSummaryWithPageHeaderAndFooter="true" 
              uuid="...">
```

### Reglas Críticas del Presupuesto de Dimensiones:
1. **Ancho de Página (`pageWidth`)**: `842` puntos (equivalente a A4 Horizontal).
2. **Alto de Página (`pageHeight`)**: `595` puntos.
3. **Márgenes Laterales**: `20` puntos en la izquierda y derecha.
4. **Ancho Imprimible Efectivo (`columnWidth`)**:
   $$\text{columnWidth} = \text{pageWidth} - \text{leftMargin} - \text{rightMargin}$$
   $$802 = 842 - 20 - 20$$
   *La suma exacta de todos los anchos de tus columnas debe ser exactamente **802** puntos.*

---

## 2. El Grid System: Mapeo Matemático de Columnas

En Excel, el diseño se rige por celdas contiguas con anchos definidos. En JasperReports, debemos calcular la coordenada $X$ de cada celda acumulando el ancho ($Width$) de las anteriores:

$$X_{n} = X_{n-1} + W_{n-1}$$

### Ejemplo Real: Matriz de Orden de Gasto (10 columnas)
La suma total debe ser exactamente `802` pt:

| # | Columna Excel | Ancho ($W$) | Coordenada $X$ de Inicio | Rol de Diseño |
|---|---|---|---|---|
| 1 | ORD. | **30** | $X=0$ | Numeración |
| 2 | DESCRIPCIÓN | **180** | $X=30$ | Texto de item (puede crecer) |
| 3 | CANT. | **50** | $X=210$ | Entero centrado |
| 4 | V. UNIT. | **70** | $X=260$ | Moneda alineado derecha |
| 5 | SUBTOTAL | **70** | $X=330$ | Moneda alineado derecha |
| 6 | IVA | **40** | $X=400$ | Moneda alineado derecha |
| 7 | OTROS IMP. | **60** | $X=440$ | Moneda alineado derecha |
| 8 | VALOR TOTAL | **70** | $X=500$ | Moneda alineado derecha |
| 9 | CÓD. PRESUP. | **110** | $X=570$ | Código presupuestario corto |
| 10| DESC. ITEM | **122** | $X=680$ | Descripción presupuestaria |
| | **SUMA TOTAL** | **802** | — | — |

### Definición XML del Encabezado de la Tabla (en `<detail>` o `<columnHeader>`):
Cada celda del grid se implementa utilizando un `<staticText>` con bordes definidos para emular las líneas de Excel:

```xml
<frame>
  <reportElement x="0" y="80" width="802" height="20" uuid="..."/>
  <!-- Celda 1: ORD -->
  <staticText>
    <reportElement mode="Opaque" x="0" y="0" width="30" height="20" backcolor="#E6E6E6"/>
    <box><pen lineWidth="0.5"/><topPen lineWidth="0.5"/><leftPen lineWidth="0.5"/><bottomPen lineWidth="0.5"/><rightPen lineWidth="0.5"/></box>
    <textElement textAlignment="Center" verticalAlignment="Middle"><font size="8" isBold="true"/></textElement>
    <text><![CDATA[ORD]]></text>
  </staticText>
  <!-- Celda 2: DESCRIPCIÓN -->
  <staticText>
    <reportElement mode="Opaque" x="30" y="0" width="180" height="20" backcolor="#E6E6E6"/>
    <box><pen lineWidth="0.5"/></box>
    <textElement textAlignment="Center" verticalAlignment="Middle"><font size="8" isBold="true"/></textElement>
    <text><![CDATA[DESCRIPCIÓN]]></text>
  </staticText>
  <!-- Celda 3: CANT -->
  <staticText>
    <reportElement mode="Opaque" x="210" y="0" width="50" height="20" backcolor="#E6E6E6"/>
    <box><pen lineWidth="0.5"/></box>
    <textElement textAlignment="Center" verticalAlignment="Middle"><font size="8" isBold="true"/></textElement>
    <text><![CDATA[CANT.]]></text>
  </staticText>
  <!-- [Continuar para las demás celdas acumulando la coordenada X...] -->
</frame>
```

---

## 3. Alineación de la Fila de Totales

Los valores sumatorios de una hoja de cálculo deben alinearse verticalmente de forma matemática debajo de sus columnas correspondientes.

### Estructura XML de Totales (Alineados con el Grid):
En la banda de `<summary>`, la fila de totales debe respetar las posiciones $X$ e $Y$:

```xml
<frame>
  <reportElement x="0" y="0" width="802" height="20" uuid="..."/>
  <!-- Texto "TOTAL GENERAL" abarcando de X=0 a X=330 (columnas 1 a 4) -->
  <staticText>
    <reportElement mode="Opaque" x="0" y="0" width="330" height="20" backcolor="#F2F2F2"/>
    <box><pen lineWidth="0.5"/></box>
    <textElement textAlignment="Right" verticalAlignment="Middle"><font size="8" isBold="true"/>
      <paragraph rightIndent="5"/>
    </textElement>
    <text><![CDATA[TOTAL GENERAL:]]></text>
  </staticText>
  
  <!-- Subtotal alineado con columna 5 (X=330, W=70) -->
  <textField>
    <reportElement x="330" y="0" width="70" height="20"/>
    <box><pen lineWidth="0.5"/></box>
    <textElement textAlignment="Right" verticalAlignment="Middle"><font size="8"/></textElement>
    <textFieldExpression><![CDATA[$P{P_TOTAL_SUBTOTAL}]]></textFieldExpression>
  </textField>
  
  <!-- IVA alineado con columna 6 (X=400, W=40) -->
  <textField>
    <reportElement x="400" y="0" width="40" height="20"/>
    <box><pen lineWidth="0.5"/></box>
    <textElement textAlignment="Right" verticalAlignment="Middle"><font size="8"/></textElement>
    <textFieldExpression><![CDATA[$P{P_TOTAL_IVA}]]></textFieldExpression>
  </textField>
  
  <!-- Otros Impuestos alineado con columna 7 (X=440, W=60) -->
  <textField>
    <reportElement x="440" y="0" width="60" height="20"/>
    <box><pen lineWidth="0.5"/></box>
    <textElement textAlignment="Right" verticalAlignment="Middle"><font size="8"/></textElement>
    <textFieldExpression><![CDATA[$P{P_TOTAL_OTROS_IMPUESTOS}]]></textFieldExpression>
  </textField>
  
  <!-- Total General alineado con columna 8 (X=500, W=70) -->
  <textField>
    <reportElement mode="Opaque" x="500" y="0" width="70" height="20" backcolor="#FFFFCC"/>
    <box><pen lineWidth="0.5"/></box>
    <textElement textAlignment="Right" verticalAlignment="Middle"><font size="8" isBold="true"/></textElement>
    <textFieldExpression><![CDATA[$P{P_TOTAL_GENERAL}]]></textFieldExpression>
  </textField>
  
  <!-- Bloque final vacío o de comentarios para las últimas columnas (X=570 a X=802, W=232) -->
  <staticText>
    <reportElement mode="Opaque" x="570" y="0" width="232" height="20" backcolor="#F2F2F2"/>
    <box><pen lineWidth="0.5"/></box>
    <text><![CDATA[]]></text>
  </staticText>
</frame>
```

---

## 4. Firmas de Responsabilidad para Firma Electrónica

> [!IMPORTANT]
> **Requisito de Espacio para Firmas Electrónicas (FirmaEC / QRs / Hashes)**
> A diferencia de las firmas manuscritas tradicionales que caben en 20-30 puntos de altura, una firma electrónica institucional inserta un bloque visual de metadatos (Nombre del firmante, Fecha, Hora, Hash MD5/SHA y a veces un código QR).
> 
> * **Altura Mínima Obligatoria**: La zona en blanco sobre la línea de firma debe medir entre **45 pt** y **60 pt** de altura. Menos de esto provocará que el bloque de firma digital tape el nombre del cargo o el texto adyacente.

### Diseño de Bloques de Firma en Paralelo (3 Firmas):
En un reporte horizontal, las firmas se colocan una al lado de la otra dividiendo el ancho de `802` pt en 3 columnas iguales:

$$\text{Ancho Firma} = \frac{802 - \text{espaciado}}{3} \approx 240 \text{ pt}$$

```xml
<!-- Contenedor general de firmas (Banda de Summary) -->
<frame>
  <reportElement x="0" y="40" width="802" height="110" positionType="Float" uuid="..."/>
  
  <!-- Firma 1: PREPARADO POR (X=0, W=240, H=110) -->
  <frame>
    <reportElement x="0" y="0" width="240" height="110"/>
    <box><pen lineWidth="0.5"/></box>
    <!-- Cabecera de la caja -->
    <staticText>
      <reportElement mode="Opaque" x="0" y="0" width="240" height="15" backcolor="#E6E6E6"/>
      <textElement textAlignment="Center"><font size="8" isBold="true"/></textElement>
      <text><![CDATA[PREPARADO POR:]]></text>
    </staticText>
    <!-- Espacio en blanco de 50pt reservado para la firma electrónica digital -->
    <staticText>
      <reportElement x="0" y="15" width="240" height="50"/>
      <text><![CDATA[]]></text>
    </staticText>
    <!-- Línea divisora -->
    <line><reportElement x="10" y="65" width="220" height="1"/></line>
    <!-- Datos del firmante -->
    <textField>
      <reportElement x="0" y="68" width="240" height="40"/>
      <textElement textAlignment="Center"><font size="8"/></textElement>
      <textFieldExpression><![CDATA["Nombre: " + $P{P_FIRMA_PREPARADO_NOMBRE} + "\nC.I: " + $P{P_FIRMA_PREPARADO_CI} + "\nCargo: " + $P{P_FIRMA_PREPARADO_CARGO}]]></textFieldExpression>
    </textField>
  </frame>

  <!-- Firma 2: REVISADO POR (X=280, W=240, H=110) -->
  <frame>
    <reportElement x="280" y="0" width="240" height="110"/>
    <box><pen lineWidth="0.5"/></box>
    <staticText>
      <reportElement mode="Opaque" x="0" y="0" width="240" height="15" backcolor="#E6E6E6"/>
      <textElement textAlignment="Center"><font size="8" isBold="true"/></textElement>
      <text><![CDATA[REVISADO POR:]]></text>
    </staticText>
    <!-- Espacio digital de 50pt -->
    <staticText>
      <reportElement x="0" y="15" width="240" height="50"/>
      <text><![CDATA[]]></text>
    </staticText>
    <line><reportElement x="10" y="65" width="220" height="1"/></line>
    <textField>
      <reportElement x="0" y="68" width="240" height="40"/>
      <textElement textAlignment="Center"><font size="8"/></textElement>
      <textFieldExpression><![CDATA["Nombre: " + $P{P_FIRMA_REVISADO_NOMBRE} + "\nC.I: " + $P{P_FIRMA_REVISADO_CI} + "\nCargo: " + $P{P_FIRMA_REVISADO_CARGO}]]></textFieldExpression>
    </textField>
  </frame>

  <!-- Firma 3: AUTORIZADO POR (X=560, W=242, H=110) -->
  <frame>
    <reportElement x="560" y="0" width="242" height="110"/>
    <box><pen lineWidth="0.5"/></box>
    <staticText>
      <reportElement mode="Opaque" x="0" y="0" width="242" height="15" backcolor="#E6E6E6"/>
      <textElement textAlignment="Center"><font size="8" isBold="true"/></textElement>
      <text><![CDATA[AUTORIZADO POR (MAXIMA AUTORIDAD O DELEGADO):]]></text>
    </staticText>
    <!-- Espacio digital de 50pt -->
    <staticText>
      <reportElement x="0" y="15" width="242" height="50"/>
      <text><![CDATA[]]></text>
    </staticText>
    <line><reportElement x="10" y="65" width="222" height="1"/></line>
    <textField>
      <reportElement x="0" y="68" width="242" height="40"/>
      <textElement textAlignment="Center"><font size="8"/></textElement>
      <textFieldExpression><![CDATA["Nombre: " + $P{P_FIRMA_AUTORIZADO_NOMBRE} + "\nC.I: " + $P{P_FIRMA_AUTORIZADO_CI} + "\nCargo: " + $P{P_FIRMA_AUTORIZADO_CARGO}]]></textFieldExpression>
    </textField>
  </frame>
</frame>
```

---

## 5. Presupuesto de Alturas para Evitar el Desborde de Página

En matrices y formularios de Excel de una sola página, el reporte resultante **debe caber exactamente en una página física**.
Para calcular el presupuesto de alturas de banda en la plantilla horizontal:

$$\text{Alto Imprimible Disponible} = \text{pageHeight} - \text{topMargin} - \text{bottomMargin}$$
$$555 \text{ pt} = 595 - 20 - 20$$

### Desglose de Alturas Recomendado:
- **`pageHeader`** (logos + cabeceras institucionales): **95 pt**
- **`detail`** (información del gasto + cabecera del grid): **188 pt**
- **`summary`** (fila de totales + firmas + notas al pie): **252 pt**
- **`pageFooter`** (códigos de documento de calidad): **20 pt**
- **Suma de alturas**: $95 + 188 + 252 + 20 = 555$ pt.
  *(Ajuste perfecto a la altura disponible. Si alguna banda supera este presupuesto, JasperReports generará automáticamente una segunda página en blanco o con desbordes).*

---

## 6. Checklist de Verificación para Conversiones de Excel

Antes de finalizar la conversión de una plantilla Excel a JRXML, verifica lo siguiente:

- [ ] **Orientación**: El archivo JRXML tiene `orientation="Landscape"` y `pageWidth="842"`.
- [ ] **Suma de Columnas**: El ancho sumado de todas las columnas es exactamente `802` pt.
- [ ] **Coordenadas X**: Cada elemento del grid comienza en $X_n = X_{n-1} + W_{n-1}$ (sin espacios ni solapamientos).
- [ ] **Totales**: Las celdas sumatorias están alineadas exactamente bajo sus columnas de origen.
- [ ] **Firmas Electrónicas**: El espacio libre para firmas digitales tiene al menos **45 pt** de altura.
- [ ] **isSummaryWithPageHeaderAndFooter**: El atributo está configurado en `true` en la raíz `<jasperReport>` para asegurar que el pie de página de calidad se repita también en la banda del summary.
- [ ] **Bordes del Grid**: Todas las celdas tienen bordes `<box>` con línea fina (`0.5` pt) para imitar las celdas de Excel.

---

*Habilidad generada en Mayo 2026 — Proyecto TESIS ESPE — Conversión Excel → JRXML*
