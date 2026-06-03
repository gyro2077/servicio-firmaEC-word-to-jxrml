#!/usr/bin/env python3
"""Genera un PDF de prueba con etiquetas [F1], [F2], [F3] usando Python stdlib."""
import sys
import zlib


def crear_pdf(ruta):
    content = (
        "BT /F1 10 Tf 50 750 Td (ORDEN DE GASTO - PRUEBA) Tj ET\n"
        "BT /F1 8 Tf 50 730 Td (Documento de prueba para firma electronica) Tj ET\n"
        "BT /F1 8 Tf 50 715 Td (Solicitado por: Ing. Juan Perez) Tj ET\n"
        "BT /F1 9 Tf 50 690 Td (Datos de la Orden:) Tj ET\n"
        "BT /F1 8 Tf 50 675 Td (Numero: OG-2026-001) Tj ET\n"
        "BT /F1 8 Tf 50 662 Td (Proveedor: MDPI AG) Tj ET\n"
        "BT /F1 8 Tf 50 649 Td (Total: $1,500.00) Tj ET\n"
        "BT /F1 7 Tf 0.996 0.996 0.996 rg 50 580 Td ([F1]) Tj ET\n"
        "BT /F1 7 Tf 0.996 0.996 0.996 rg 153 580 Td ([F2]) Tj ET\n"
        "BT /F1 7 Tf 0.996 0.996 0.996 rg 256 580 Td ([F3]) Tj ET\n"
        "BT /F1 8 Tf 50 490 Td (SOLICITADO POR:) Tj "
        "163 490 Td (PREPARADO POR:) Tj 276 490 Td (AUTORIZADO POR:) Tj ET\n"
        "BT /F1 7 Tf 50 440 Td (Ing. Juan Perez) Tj "
        "50 430 Td (CI: 1234567890) Tj "
        "163 440 Td (Ing. Maria Garcia) Tj "
        "163 430 Td (CI: 0987654321) Tj "
        "276 440 Td (Ing. Carlos Lopez) Tj "
        "276 430 Td (CI: 1122334455) Tj ET\n"
        "BT /F1 6 Tf 50 410 Td (ANALISTA) Tj "
        "163 410 Td (JEFE DE GRUPO) Tj 276 410 Td (DIRECTOR) Tj ET\n"
    )
    comp = zlib.compress(content.encode("latin-1"))

    parts = bytearray()
    parts.extend(b"%PDF-1.4\n")

    off1 = len(parts)
    parts.extend(
        b"1 0 obj<</Type /Font /Subtype /Type1 /BaseFont /Helvetica>>endobj\n"
    )

    off2 = len(parts)
    parts.extend(
        b"2 0 obj<</Length " + str(len(comp)).encode() + b" /Filter /FlateDecode>>stream\n"
    )
    parts.extend(comp)
    parts.extend(b"\nendstream\nendobj\n")

    off3 = len(parts)
    parts.extend(
        b"3 0 obj<</Type /Page /Parent 4 0 R /MediaBox [0 0 612 792]"
        b"/Contents 2 0 R/Resources<</Font<</F1 1 0 R>>>>>>endobj\n"
    )

    off4 = len(parts)
    parts.extend(b"4 0 obj<</Type /Pages /Kids[3 0 R]/Count 1>>endobj\n")

    off5 = len(parts)
    parts.extend(b"5 0 obj<</Type /Catalog /Pages 4 0 R>>endobj\n")

    body_len = len(parts)

    offsets = [0, off1, off2, off3, off4, off5]

    xref = b"xref\n0 6\n0000000000 65535 f \n"
    for off in offsets:
        xref += b"%010d 00000 n \n" % off

    trailer = b"trailer<</Size 6/Root 5 0 R>>\nstartxref\n%d\n%%%%EOF" % body_len

    with open(ruta, "wb") as f:
        f.write(parts)
        f.write(xref)
        f.write(trailer)

    print(f"PDF generado: {ruta}")


if __name__ == "__main__":
    crear_pdf(sys.argv[1] if len(sys.argv) > 1 else "documento_prueba_anclas.pdf")
