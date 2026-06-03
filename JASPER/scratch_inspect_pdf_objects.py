import re

pdf_path = "../Anexo_Unico_Estandarizado_Firma_Docente_Plantilla/anexoFirmaDocente.pdf"

with open(pdf_path, "rb") as f:
    content = f.read()

# Let's search for Font descriptors and BaseFont settings in the PDF binary
base_fonts = re.findall(b"/BaseFont\s*/([A-Za-z0-9,-]+)", content)
print("Base Fonts found in PDF:")
for bf in set(base_fonts):
    print(" -", bf.decode("utf-8", errors="ignore"))

# Let's search for Font objects in general
fonts = re.findall(b"/Type\s*/Font\s*/Subtype\s*/([A-Za-z0-9]+)", content)
print("Fonts subtypes:")
for ft in set(fonts):
    print(" -", ft.decode("utf-8", errors="ignore"))
