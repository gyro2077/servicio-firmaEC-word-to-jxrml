package ec.edu.espe.gestion_publicaciones.firmaec.service;

import org.apache.pdfbox.Loader;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.PDPage;
import org.apache.pdfbox.pdmodel.common.PDRectangle;
import org.apache.pdfbox.text.PDFTextStripper;
import org.apache.pdfbox.text.TextPosition;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

@Component
public class PdfSignatureLocator {

    public byte[] normalizarRotacion(byte[] pdfBytes) {
        try (PDDocument document = Loader.loadPDF(pdfBytes)) {
            boolean modificado = false;
            int totalPages = document.getNumberOfPages();
            for (int pageNum = 0; pageNum < totalPages; pageNum++) {
                PDPage page = document.getPage(pageNum);
                int rotation = page.getRotation();
                if (rotation == 90 || rotation == 270) {
                    PDRectangle mediaBox = page.getMediaBox();
                    float w = mediaBox.getWidth();
                    float h = mediaBox.getHeight();
                    
                    page.setMediaBox(new PDRectangle(0, 0, h, w));
                    if (page.getCropBox() != null) {
                        page.setCropBox(new PDRectangle(0, 0, h, w));
                    }
                    
                    try (org.apache.pdfbox.pdmodel.PDPageContentStream cs =
                            new org.apache.pdfbox.pdmodel.PDPageContentStream(
                                document, page,
                                org.apache.pdfbox.pdmodel.PDPageContentStream.AppendMode.PREPEND,
                                false, false)) {
                        
                        if (rotation == 90) {
                            cs.transform(org.apache.pdfbox.util.Matrix.getRotateInstance(Math.toRadians(-90), 0, w));
                        } else {
                            cs.transform(org.apache.pdfbox.util.Matrix.getRotateInstance(Math.toRadians(90), h, 0));
                        }
                    }
                    
                    page.setRotation(0);
                    modificado = true;
                }
            }
            if (modificado) {
                java.io.ByteArrayOutputStream baos = new java.io.ByteArrayOutputStream();
                document.save(baos);
                return baos.toByteArray();
            }
        } catch (IOException e) {
            System.err.println("Error normalizando rotación del PDF: " + e.getMessage());
        }
        return pdfBytes;
    }

    public int[] localizarFirma(byte[] pdfBytes, int turnoFirma) {
        return localizarFirma(pdfBytes, turnoFirma, null);
    }

    public int[] localizarFirma(byte[] pdfBytes, int turnoFirma, String subIndice) {
        String etiqueta = subIndice != null
                ? "[F" + turnoFirma + subIndice + "]"
                : "[F" + turnoFirma + "]";

        float[] coords = findTextCoordinates(pdfBytes, etiqueta);
        if (coords != null) {
            int offsetY = 15;
            return new int[]{
                (int) coords[0],
                (int) (coords[1] + offsetY),
                (int) coords[2]
            };
        }
        return null;
    }

    public boolean esDobleEstampado(byte[] pdfBytes, int turnoFirma) {
        String etiquetaA = "[F" + turnoFirma + "A]";
        String etiquetaB = "[F" + turnoFirma + "B]";
        return findTextCoordinates(pdfBytes, etiquetaA) != null
            && findTextCoordinates(pdfBytes, etiquetaB) != null;
    }

    public int detectarTotalFirmas(byte[] pdfBytes) {
        int total = 0;
        for (int i = 1; i <= 10; i++) {
            String etiqueta = "[F" + i + "]";
            String etiquetaA = "[F" + i + "A]";
            if (findTextCoordinates(pdfBytes, etiqueta) != null
                || findTextCoordinates(pdfBytes, etiquetaA) != null) {
                total = i;
            } else {
                break;
            }
        }
        return total;
    }

    private float[] findTextCoordinates(byte[] pdfBytes, String searchText) {
        try (PDDocument document = Loader.loadPDF(pdfBytes)) {
            int totalPages = document.getNumberOfPages();

            for (int pageNum = 0; pageNum < totalPages; pageNum++) {
                PDPage page = document.getPage(pageNum);
                PDRectangle mediaBox = page.getMediaBox();
                float pageHeight = mediaBox.getHeight();

                TextPositionExtractor extractor =
                    new TextPositionExtractor(document, pageNum, searchText);
                extractor.extractTextPositions();

                if (extractor.foundPosition != null) {
                    float x = extractor.foundPosition.getX();
                    float y = extractor.foundPosition.getY();
                    int rotation = page.getRotation();

                    float finalX;
                    float finalY;

                    if (rotation == 90) {
                        finalX = y;
                        finalY = x;
                    } else if (rotation == 270) {
                        float pageWidth = mediaBox.getWidth();
                        finalX = pageHeight - y;
                        finalY = pageWidth - x;
                    } else if (rotation == 180) {
                        float pageWidth = mediaBox.getWidth();
                        finalX = pageWidth - x;
                        finalY = y;
                    } else {
                        // 0 degrees rotation
                        finalX = x;
                        finalY = pageHeight - y;
                    }

                    return new float[]{finalX, finalY, pageNum + 1};
                }
            }
        } catch (IOException e) {
            System.err.println("PdfSignatureLocator: Error escaneando PDF - " + e.getMessage());
        }
        return null;
    }

    private static class TextPositionExtractor extends PDFTextStripper {
        private final String searchText;
        private final StringBuilder currentLine = new StringBuilder();
        private final List<TextPosition> currentPositions = new ArrayList<>();
        TextPosition foundPosition = null;

        TextPositionExtractor(PDDocument document, int pageNum, String searchText)
                throws IOException {
            super();
            this.document = document;
            this.searchText = searchText;
            this.setStartPage(pageNum + 1);
            this.setEndPage(pageNum + 1);
        }

        void extractTextPositions() throws IOException {
            this.getText(document);
        }

        @Override
        protected void writeString(String string, List<TextPosition> textPositions)
                throws IOException {
            for (TextPosition tp : textPositions) {
                currentLine.append(tp.getUnicode());
                currentPositions.add(tp);
            }

            String line = currentLine.toString();
            int idx = line.indexOf(searchText);
            if (idx >= 0 && foundPosition == null) {
                foundPosition = currentPositions.get(idx);
            }
        }

        @Override
        protected void writeLineSeparator() throws IOException {
            currentLine.setLength(0);
            currentPositions.clear();
            super.writeLineSeparator();
        }
    }
}
