import xml.etree.ElementTree as ET
import sys
import os

def convert_jrxml(input_path, output_path):
    ET.register_namespace('', 'http://jasperreports.sourceforge.net/jasperreports')
    
    tree = ET.parse(input_path)
    root = tree.getroot()
    
    ns = 'http://jasperreports.sourceforge.net/jasperreports'
    
    # 0. Clean root element attributes
    if 'uuid' in root.attrib:
        del root.attrib['uuid']
    if 'summaryWithPageHeaderAndFooter' in root.attrib:
        val = root.attrib['summaryWithPageHeaderAndFooter']
        del root.attrib['summaryWithPageHeaderAndFooter']
        root.attrib['isSummaryWithPageHeaderAndFooter'] = val
        
    # Clean splitType from all band elements
    for band in root.findall('.//jr:band', {'jr': ns}):
        if 'splitType' in band.attrib:
            del band.attrib['splitType']
            
    # Clean splitType or height from layout sections (pageHeader, detail, etc.)
    # In legacy schema, elements like <pageHeader>, <detail> cannot have attributes like splitType or height!
    # All height and splitType MUST be inside their <band> child.
    for tag in ['background', 'title', 'pageHeader', 'columnHeader', 'detail', 'columnFooter', 'pageFooter', 'lastPageFooter', 'summary']:
        for sec in root.findall(f'.//jr:{tag}', {'jr': ns}):
            if 'splitType' in sec.attrib:
                del sec.attrib['splitType']
            if 'height' in sec.attrib:
                h_val = sec.attrib['height']
                del sec.attrib['height']
                band = sec.find(f'{{{ns}}}band')
                if band is not None:
                    band.attrib['height'] = h_val
                else:
                    band = ET.SubElement(sec, f'{{{ns}}}band', {'height': h_val})

    # Procesar de forma recursiva
    def process_element(parent, element):
        # Si el elemento es un <element kind="...">
        if element.tag == f'{{{ns}}}element':
            kind = element.attrib.get('kind')
            if not kind:
                return
            
            new_el = ET.Element(f'{{{ns}}}{kind}')
            
            re_attrs = {}
            for attr in ['x', 'y', 'width', 'height', 'uuid', 'stretchType', 'mode', 'backcolor', 'forecolor']:
                if attr in element.attrib:
                    re_attrs[attr] = element.attrib[attr]
            
            re = ET.SubElement(new_el, f'{{{ns}}}reportElement', re_attrs)
            
            box_el = element.find(f'{{{ns}}}box')
            if box_el is not None:
                new_el.append(box_el)
            
            has_font = any(attr in element.attrib for attr in ['fontName', 'fontSize', 'bold', 'italic'])
            has_align = any(attr in element.attrib for attr in ['hTextAlign', 'vTextAlign'])
            
            if has_font or has_align:
                te = ET.SubElement(new_el, f'{{{ns}}}textElement')
                
                if 'hTextAlign' in element.attrib:
                    te.set('textAlignment', element.attrib['hTextAlign'])
                if 'vTextAlign' in element.attrib:
                    te.set('verticalAlignment', element.attrib['vTextAlign'])
                
                if has_font:
                    font_attrs = {}
                    if 'fontName' in element.attrib:
                        font_attrs['fontName'] = element.attrib['fontName']
                    if 'fontSize' in element.attrib:
                        font_attrs['size'] = str(int(float(element.attrib['fontSize'])))
                    if 'bold' in element.attrib:
                        font_attrs['isBold'] = element.attrib['bold']
                    if 'italic' in element.attrib:
                        font_attrs['isItalic'] = element.attrib['italic']
                    
                    ET.SubElement(te, f'{{{ns}}}font', font_attrs)
            
            if kind == 'textField':
                if 'evaluationTime' in element.attrib:
                    new_el.set('evaluationTime', element.attrib['evaluationTime'])
                if 'textAdjust' in element.attrib:
                    if element.attrib['textAdjust'] == 'StretchHeight':
                        new_el.set('isStretchWithOverflow', 'true')
            
            for child in list(element):
                if child.tag == f'{{{ns}}}expression':
                    if kind == 'textField':
                        expr_tag = f'{{{ns}}}textFieldExpression'
                    elif kind == 'image':
                        expr_tag = f'{{{ns}}}imageExpression'
                    else:
                        expr_tag = f'{{{ns}}}expression'
                    
                    new_expr = ET.SubElement(new_el, expr_tag)
                    new_expr.text = child.text
                    for k, v in child.attrib.items():
                        new_expr.set(k, v)
                elif child.tag == f'{{{ns}}}box':
                    pass
                else:
                    process_element(new_el, child)
            
            for p in root.iter():
                if element in list(p):
                    idx = list(p).index(element)
                    p.remove(element)
                    p.insert(idx, new_el)
                    break
            
        else:
            for child in list(element):
                process_element(element, child)

    process_element(root, root)
    
    # Escribir el resultado
    tree.write(output_path, encoding='UTF-8', xml_declaration=True)
    print(f"Conversión finalizada con éxito. Guardado en: {output_path}")

if __name__ == '__main__':
    if len(sys.argv) < 3:
        print("Uso: python3 convert_jrxml.py <input.jrxml> <output.jrxml>")
        sys.exit(1)
    convert_jrxml(sys.argv[1], sys.argv[2])
