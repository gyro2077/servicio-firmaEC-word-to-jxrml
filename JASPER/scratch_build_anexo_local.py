import os

output_path = "/home/gyro/Documents/TESIS/word-to-jrxml/Anexo_Unico_Estandarizado_Firma_Docente_Plantilla/anexoFirmaDocente.jrxml"

# We will build the JRXML dynamically.
jrxml = []

# XML Header
jrxml.append("""<?xml version="1.0" encoding="UTF-8"?>
<jasperReport xmlns="http://jasperreports.sourceforge.net/jasperreports" 
              xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
              xsi:schemaLocation="http://jasperreports.sourceforge.net/jasperreports http://jasperreports.sourceforge.net/xsd/jasperreport.xsd" 
              name="anexoFirmaDocente" 
              language="groovy" 
              pageWidth="595" 
              pageHeight="842" 
              whenNoDataType="AllSectionsNoDetail" 
              columnWidth="555" 
              leftMargin="20" 
              rightMargin="20" 
              topMargin="20" 
              bottomMargin="20" 
              uuid="c96589ee-fb08-28c0-7179-095bcd0cef5f">
              
	<property name="ireport.zoom" value="2.0" />
	<property name="ireport.x" value="0" />
	<property name="ireport.y" value="0" />

	<!-- Parámetros -->
	<parameter name="selloSPP" class="java.lang.String">
		<defaultValueExpression><![CDATA["selloAnexoFirmaDocente.png"]]></defaultValueExpression>
	</parameter>
	<parameter name="P_NUMERO_ANEXO" class="java.lang.String">
		<defaultValueExpression><![CDATA["1"]]></defaultValueExpression>
	</parameter>
	<parameter name="P_FECHA_DOCUMENTO" class="java.lang.String">
		<defaultValueExpression><![CDATA["27/05/2026"]]></defaultValueExpression>
	</parameter>
	<parameter name="P_DEPARTAMENTO" class="java.lang.String">
		<defaultValueExpression><![CDATA["Vicerrectorado de Investigación, Innovación y Transferencia Tecnológica"]]></defaultValueExpression>
	</parameter>
	<parameter name="P_DOCENTE_SOLICITANTE_NOMBRE" class="java.lang.String">
		<defaultValueExpression><![CDATA["JUAN PEREZ"]]></defaultValueExpression>
	</parameter>
	<parameter name="P_DOCENTE_SOLICITANTE_IDENTIFICACION" class="java.lang.String">
		<defaultValueExpression><![CDATA["1712345678"]]></defaultValueExpression>
	</parameter>
	<parameter name="P_DOCENTE_SOLICITANTE_CARGO" class="java.lang.String">
		<defaultValueExpression><![CDATA["DOCENTE DE APOYO DE INVESTIGACION"]]></defaultValueExpression>
	</parameter>
	<parameter name="P_TITULO_ARTICULO" class="java.lang.String">
		<defaultValueExpression><![CDATA["DISEÑO DE UN SISTEMA EXPERTO"]]></defaultValueExpression>
	</parameter>
	<parameter name="P_DESTINO_PUBLICACION" class="java.lang.String">
		<defaultValueExpression><![CDATA["REVISTA IEEE"]]></defaultValueExpression>
	</parameter>
	<parameter name="P_AUTORES_TEXTO" class="java.lang.String">
		<defaultValueExpression><![CDATA["JUAN PEREZ, MARIA GOMEZ"]]></defaultValueExpression>
	</parameter>
	<parameter name="P_BLOQUE_APORTES_AUTORES" class="java.lang.String">
		<defaultValueExpression><![CDATA["JUAN PEREZ: 60%, MARIA GOMEZ: 40%"]]></defaultValueExpression>
	</parameter>
	<parameter name="P_PRESENTADOR_NOMBRE" class="java.lang.String">
		<defaultValueExpression><![CDATA["JUAN PEREZ"]]></defaultValueExpression>
	</parameter>
	<parameter name="P_CIUDAD" class="java.lang.String">
		<defaultValueExpression><![CDATA["Sangolquí"]]></defaultValueExpression>
	</parameter>
	<parameter name="P_FECHA_LARGA" class="java.lang.String">
		<defaultValueExpression><![CDATA["27 de mayo de 2026"]]></defaultValueExpression>
	</parameter>

	<queryString>
		<![CDATA[select 1 as dummy]]>
	</queryString>
	
	<background>
		<band splitType="Stretch" />
	</background>
	
	<title>
		<band splitType="Stretch" />
	</title>

	<pageHeader>
		<band height="95" splitType="Stretch">
			<!-- Encabezado Institucional -->
			<frame>
				<reportElement x="0" y="0" width="555" height="95" uuid="68fb85f8-8e44-0cac-ffa6-df71ea549961" />
				<box>
					<pen lineWidth="0.5" />
				</box>
				<line>
					<reportElement x="110" y="0" width="1" height="95" uuid="4466d14b-6761-2af3-1c4c-bc7bbfcdfb07" />
				</line>
				<line>
					<reportElement x="424" y="0" width="1" height="95" uuid="bdabefcb-a7d0-341f-852f-434ea6fe3189" />
				</line>
				<image>
					<reportElement x="10" y="15" width="90" height="65" uuid="90ce6ae1-c205-4ecf-6563-1f97c0492341" />
					<imageExpression><![CDATA[$P{selloSPP}.toString()]]></imageExpression>
				</image>
				<textField>
					<reportElement x="115" y="10" width="304" height="75" uuid="5e4e2078-b9b4-7229-e01a-195fe4d34f24" />
					<textElement textAlignment="Center" verticalAlignment="Middle">
						<font fontName="Helvetica" size="10" isBold="true" />
					</textElement>
					<textFieldExpression><![CDATA["SOLICITUD DE FONDOS PARA PUBLICACIONES INDEXADAS, Y PARTICIPACIÓN EN CONGRESOS O CONFERENCIAS SIN MOVILIDAD"]]></textFieldExpression>
				</textField>
				
				<!-- Columna 3 -->
				<frame>
					<reportElement x="424" y="0" width="131" height="95" uuid="d77124eb-7fa1-29fc-0154-103be1ced95c" />
					<box><pen lineWidth="0.0"/></box>
					
					<!-- Unidad de Gestión... -->
					<textField isStretchWithOverflow="true">
						<reportElement x="3" y="3" width="125" height="42" uuid="d77124eb-7fa1-29fc-0154-103be1ced95d" />
						<textElement textAlignment="Center" verticalAlignment="Middle">
							<font fontName="Helvetica" size="7" isBold="true" />
						</textElement>
						<textFieldExpression><![CDATA["Unidad de Gestión de la\\nInvestigación"]]></textFieldExpression>
					</textField>
					
					<!-- Línea horizontal superior en y=48 -->
					<line>
						<reportElement x="0" y="48" width="131" height="1" uuid="d67a274a-671e-4333-9d23-30bc6abf95b6" />
					</line>
					<!-- Línea horizontal inferior en y=71 -->
					<line>
						<reportElement x="0" y="71" width="131" height="1" uuid="19f506ef-2976-4f36-91ef-d8671c7bae02" />
					</line>
					<!-- Línea vertical divisora en x=58 -->
					<line>
						<reportElement x="58" y="48" width="1" height="47" uuid="55c10c0e-504c-460e-8f94-bdcf91953d5e" />
					</line>
					
					<!-- \"Pág.\" label (y=48 a 71) -->
					<staticText>
						<reportElement x="0" y="48" width="58" height="23" uuid="422b69e0-6472-a4a5-c97b-2947fb8f3ed4" />
						<textElement textAlignment="Center" verticalAlignment="Middle">
							<font fontName="Helvetica" size="7" isBold="true" />
						</textElement>
						<text><![CDATA[Pág.]]></text>
					</staticText>
					
					<!-- Página Value (y=48 a 71 - Dynamic page numbering) -->
					<textField>
						<reportElement x="60" y="48" width="30" height="23" uuid="f833afbf-8c7d-9c7d-1d60-f9b4a9293297" />
						<textElement textAlignment="Right" verticalAlignment="Middle">
							<font fontName="Helvetica" size="7" />
						</textElement>
						<textFieldExpression><![CDATA[$V{PAGE_NUMBER} + " de"]]></textFieldExpression>
					</textField>
					<textField evaluationTime="Report">
						<reportElement x="90" y="48" width="38" height="23" uuid="f833afbf-8c7d-9c7d-1d60-f9b4a9293298" />
						<textElement textAlignment="Left" verticalAlignment="Middle">
							<font fontName="Helvetica" size="7" />
						</textElement>
						<textFieldExpression><![CDATA[" " + $V{PAGE_NUMBER}]]></textFieldExpression>
					</textField>
					
					<!-- \"Fecha:\" label (y=71 a 95) -->
					<staticText>
						<reportElement x="0" y="71" width="58" height="24" uuid="cedd1185-99a0-8d4c-a0ee-a179966b04e8" />
						<textElement textAlignment="Center" verticalAlignment="Middle">
							<font fontName="Helvetica" size="7" isBold="true" />
						</textElement>
						<text><![CDATA[Fecha:]]></text>
					</staticText>
					
					<!-- Fecha Value (y=71 a 95) -->
					<textField>
						<reportElement x="60" y="71" width="68" height="24" uuid="fbf8d0e0-006e-2fda-88ca-1d382fd935b1" />
						<textElement textAlignment="Center" verticalAlignment="Middle">
							<font fontName="Helvetica" size="7" />
						</textElement>
						<textFieldExpression><![CDATA[$P{P_FECHA_DOCUMENTO}]]></textFieldExpression>
					</textField>
				</frame>
			</frame>
		</band>
	</pageHeader>
	
	<detail>
		<!-- Band 1: Página 1 Content -->
		<band height="500" splitType="Stretch">
			<!-- Titulo: Anexo -->
			<textField isStretchWithOverflow="true">
				<reportElement x="0" y="20" width="555" height="15" uuid="9dfbc2c9-b1e1-7797-e550-62b21eaba4c1" positionType="Float" />
				<textElement textAlignment="Center">
					<font fontName="Helvetica" size="11" isBold="true" />
				</textElement>
				<textFieldExpression><![CDATA["Anexo " + $P{P_NUMERO_ANEXO}]]></textFieldExpression>
			</textField>

			<!-- Titulo: Universidad -->
			<textField isStretchWithOverflow="true">
				<reportElement x="0" y="55" width="555" height="15" uuid="9dfbc2c9-b1e1-7797-e550-62b21eaba4c2" positionType="Float" />
				<textElement textAlignment="Center">
					<font fontName="Helvetica" size="11" isBold="true" />
				</textElement>
				<textFieldExpression><![CDATA["UNIVERSIDAD DE LAS FUERZAS ARMADAS – ESPE"]]></textFieldExpression>
			</textField>

			<!-- Titulo: Departamento -->
			<textField isStretchWithOverflow="true">
				<reportElement x="0" y="70" width="555" height="15" uuid="9dfbc2c9-b1e1-7797-e550-62b21eaba4ea" positionType="Float" />
				<textElement textAlignment="Center">
					<font fontName="Helvetica" size="11" />
				</textElement>
				<textFieldExpression><![CDATA[$P{P_DEPARTAMENTO}]]></textFieldExpression>
			</textField>

			<!-- Titulo: Declaracion -->
			<textField isStretchWithOverflow="true">
				<reportElement x="0" y="105" width="555" height="30" uuid="9dfbc2c9-b1e1-7797-e550-62b21eaba4c3" positionType="Float" />
				<textElement textAlignment="Center">
					<font fontName="Helvetica" size="11" isBold="true" />
				</textElement>
				<textFieldExpression><![CDATA["DECLARACIÓN INTEGRAL DE AUTORÍA, NO AFECTACIÓN A PROPIEDAD INTELECTUAL Y ACUERDO DE PRESENTACIÓN"]]></textFieldExpression>
			</textField>

			<!-- P3: Docente Intro -->
			<textField isStretchWithOverflow="true">
				<reportElement x="0" y="150" width="555" height="60" uuid="9dfbc2c9-b1e1-7797-e550-62b21eaba4c4" positionType="Float" />
				<textElement textAlignment="Justified" markup="html">
					<font fontName="Helvetica" size="11" />
				</textElement>
				<textFieldExpression><![CDATA["El/la docente solicitante <b><u>    " + $P{P_DOCENTE_SOLICITANTE_NOMBRE} + "    </u></b>, con identificación No. <b><u>    " + $P{P_DOCENTE_SOLICITANTE_IDENTIFICACION} + "    </u></b>, en calidad de responsable de la solicitud de fondos para el artículo titulado <b><u>    " + $P{P_TITULO_ARTICULO} + "    </u></b>, a ser publicado o presentado en <b><u>    " + $P{P_DESTINO_PUBLICACION} + "    </u></b>, con base en la información registrada en el expediente y en el sistema institucional, <b>CERTIFICA, DECLARA Y ACUERDA</b> lo siguiente:"]]></textFieldExpression>
			</textField>

			<!-- P4: 1. Informacion -->
			<textField isStretchWithOverflow="true">
				<reportElement x="0" y="225" width="555" height="15" uuid="9dfbc2c9-b1e1-7797-e550-62b21eaba4c5" positionType="Float" />
				<textElement textAlignment="Left">
					<font fontName="Helvetica" size="11" isBold="true" />
				</textElement>
				<textFieldExpression><![CDATA["1. Información de autoría y financiamiento"]]></textFieldExpression>
			</textField>

			<!-- P5: Informacion body -->
			<textField isStretchWithOverflow="true">
				<reportElement x="0" y="240" width="555" height="45" uuid="9dfbc2c9-b1e1-7797-e550-62b21eaba4c6" positionType="Float" />
				<textElement textAlignment="Justified" markup="html">
					<font fontName="Helvetica" size="11" />
				</textElement>
				<textFieldExpression><![CDATA["Que el artículo registra como autores a <b><u>    " + $P{P_AUTORES_TEXTO} + "    </u></b>. El contenido del artículo corresponde a una investigación desarrollada por dichos autores, respetando los derechos de propiedad intelectual de terceros. Asimismo, se deja constancia de que la presente publicación <b>NO</b> ha sido financiada previamente ni se encuentra en proceso de financiamiento por otras Instituciones de Educación Superior, centros, entidades u organismos."]]></textFieldExpression>
			</textField>

			<!-- P6: 2. Declaracion -->
			<textField isStretchWithOverflow="true">
				<reportElement x="0" y="300" width="555" height="15" uuid="9dfbc2c9-b1e1-7797-e550-62b21eaba4c7" positionType="Float" />
				<textElement textAlignment="Left">
					<font fontName="Helvetica" size="11" isBold="true" />
				</textElement>
				<textFieldExpression><![CDATA["2. Declaración de no afectación a propiedad intelectual"]]></textFieldExpression>
			</textField>

			<!-- P7: Declaracion body -->
			<textField isStretchWithOverflow="true">
				<reportElement x="0" y="315" width="555" height="30" uuid="9dfbc2c9-b1e1-7797-e550-62b21eaba4c8" positionType="Float" />
				<textElement textAlignment="Justified" markup="html">
					<font fontName="Helvetica" size="11" />
				</textElement>
				<textFieldExpression><![CDATA["Que la publicación o presentación del artículo <b>NO</b> genera afectación a la condición de novedad en el ámbito de la protección de la propiedad intelectual con fines de transferencia de tecnología."]]></textFieldExpression>
			</textField>

			<!-- P8: 3. Aporte autores -->
			<textField isStretchWithOverflow="true">
				<reportElement x="0" y="360" width="555" height="15" uuid="9dfbc2c9-b1e1-7797-e550-62b21eaba4c9" positionType="Float" />
				<textElement textAlignment="Left">
					<font fontName="Helvetica" size="11" isBold="true" />
				</textElement>
				<textFieldExpression><![CDATA["3. Aporte de los autores"]]></textFieldExpression>
			</textField>

			<!-- P9: Aporte intro -->
			<textField isStretchWithOverflow="true">
				<reportElement x="0" y="375" width="555" height="15" uuid="9dfbc2c9-b1e1-7797-e550-62b21eaba4d0" positionType="Float" />
				<textElement textAlignment="Justified">
					<font fontName="Helvetica" size="11" />
				</textElement>
				<textFieldExpression><![CDATA["Además, se registra que el aporte de cada autor es el siguiente:"]]></textFieldExpression>
			</textField>

			<!-- P10: Aporte body -->
			<textField isStretchWithOverflow="true">
				<reportElement x="30" y="395" width="525" height="25" uuid="9dfbc2c9-b1e1-7797-e550-62b21eaba4d1" positionType="Float" />
				<textElement textAlignment="Left" markup="html">
					<font fontName="Helvetica" size="11" />
				</textElement>
				<textFieldExpression><![CDATA["<b><u>    " + $P{P_BLOQUE_APORTES_AUTORES} + "    </u></b>"]]></textFieldExpression>
			</textField>

			<!-- P11: 4. Acuerdo presentacion -->
			<textField isStretchWithOverflow="true">
				<reportElement x="0" y="435" width="555" height="15" uuid="9dfbc2c9-b1e1-7797-e550-62b21eaba4d2" positionType="Float" />
				<textElement textAlignment="Left">
					<font fontName="Helvetica" size="11" isBold="true" />
				</textElement>
				<textFieldExpression><![CDATA["4. Acuerdo de presentación"]]></textFieldExpression>
			</textField>

			<!-- P12: Acuerdo body -->
			<textField isStretchWithOverflow="true">
				<reportElement x="0" y="450" width="555" height="45" uuid="9dfbc2c9-b1e1-7797-e550-62b21eaba4d3" positionType="Float" />
				<textElement textAlignment="Justified" markup="html">
					<font fontName="Helvetica" size="11" />
				</textElement>
				<textFieldExpression><![CDATA["Cuando el proceso implique pago de publicaciones a ser presentadas en congresos o conferencias sin movilidad, se registra como responsable de la presentación del artículo a <b><u>    " + $P{P_PRESENTADOR_NOMBRE} + "    </u></b>. En caso de que no aplique presentación, el sistema deberá registrar esta cláusula como  <b>NO APLICA</b>."]]></textFieldExpression>
			</textField>
		</band>

		<!-- Band 2: Página 2 Content -->
		<band height="270" splitType="Stretch">
			<break>
				<reportElement x="0" y="0" width="100" height="1" uuid="88fb85f8-8e44-0cac-ffa6-df71ea549970" />
			</break>
			
			<!-- P13: Ciudad y fecha -->
			<textField isStretchWithOverflow="true">
				<reportElement x="0" y="10" width="555" height="15" uuid="9dfbc2c9-b1e1-7797-e550-62b21eaba4d4" positionType="Float" />
				<textElement textAlignment="Right" markup="html">
					<font fontName="Helvetica" size="11" />
				</textElement>
				<textFieldExpression><![CDATA[$P{P_CIUDAD} + ",  <b><u>    " + $P{P_FECHA_LARGA} + "    </u></b>"]]></textFieldExpression>
			</textField>

			<!-- P14: 5. Firma title -->
			<textField isStretchWithOverflow="true">
				<reportElement x="0" y="40" width="555" height="15" uuid="9dfbc2c9-b1e1-7797-e550-62b21eaba4d5" positionType="Float" />
				<textElement textAlignment="Left">
					<font fontName="Helvetica" size="11" isBold="true" />
				</textElement>
				<textFieldExpression><![CDATA["5. Firma del docente solicitante"]]></textFieldExpression>
			</textField>

			<!-- P15: Firma body -->
			<textField isStretchWithOverflow="true">
				<reportElement x="0" y="55" width="555" height="30" uuid="9dfbc2c9-b1e1-7797-e550-62b21eaba4d6" positionType="Float" />
				<textElement textAlignment="Justified">
					<font fontName="Helvetica" size="10" />
				</textElement>
				<textFieldExpression><![CDATA["Para efectos de trámite, el presente documento será suscrito únicamente por el/la docente solicitante, quien deja constancia de la veracidad de la información registrada en la solicitud y en el expediente correspondiente."]]></textFieldExpression>
			</textField>

			<!-- Bloque de Firma -->
			<frame>
				<reportElement x="0" y="100" width="555" height="135" uuid="7d7722ed-4bdd-441c-9ed1-d5021a5dffac" positionType="Float" />
				<textField>
					<reportElement x="0" y="60" width="555" height="15" uuid="cec7c112-8f8d-4c2a-bda2-511a66e6b9fa" />
					<textElement textAlignment="Center">
						<font fontName="Helvetica" size="11" />
					</textElement>
					<textFieldExpression><![CDATA["__________________________________"]]></textFieldExpression>
				</textField>
				<textField>
					<reportElement x="0" y="75" width="555" height="15" uuid="cec7c112-8f8d-4c2a-bda2-511a66e6b9fb" />
					<textElement textAlignment="Center">
						<font fontName="Helvetica" size="10" />
					</textElement>
					<textFieldExpression><![CDATA["Firma"]]></textFieldExpression>
				</textField>
				<textField>
					<reportElement x="0" y="90" width="555" height="15" uuid="cec7c112-8f8d-4c2a-bda2-511a66e6b9fc" />
					<textElement textAlignment="Center" markup="html">
						<font fontName="Helvetica" size="10" />
					</textElement>
					<textFieldExpression><![CDATA["<b><u>    " + $P{P_DOCENTE_SOLICITANTE_NOMBRE} + "    </u></b>"]]></textFieldExpression>
				</textField>
				<textField>
					<reportElement x="0" y="105" width="555" height="15" uuid="cec7c112-8f8d-4c2a-bda2-511a66e6b9fd" />
					<textElement textAlignment="Center">
						<font fontName="Helvetica" size="10" isBold="true" />
					</textElement>
					<textFieldExpression><![CDATA["CI: " + $P{P_DOCENTE_SOLICITANTE_IDENTIFICACION}]]></textFieldExpression>
				</textField>
				<textField>
					<reportElement x="0" y="120" width="555" height="15" uuid="cec7c112-8f8d-4c2a-bda2-511a66e6b9fe" />
					<textElement textAlignment="Center">
						<font fontName="Helvetica" size="10" isBold="true" />
					</textElement>
					<textFieldExpression><![CDATA[$P{P_DOCENTE_SOLICITANTE_CARGO}]]></textFieldExpression>
				</textField>
			</frame>
		</band>
	</detail>
</jasperReport>
""")

# Write to file
with open(output_path, "w", encoding="utf-8") as f:
	f.write("".join(jrxml))

print("✓ JRXML file for Anexo Único generated successfully at:", output_path)
