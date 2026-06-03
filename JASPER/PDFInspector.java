import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.text.PDFTextStripper;
import org.apache.pdfbox.text.TextPosition;
import java.io.File;
import java.io.IOException;
import java.util.List;

public class PDFInspector extends PDFTextStripper {
    public PDFInspector() throws IOException {
        super();
    }

    @Override
    protected void writeString(String string, List<TextPosition> textPositions) throws IOException {
        for (TextPosition text : textPositions) {
            String fontName = text.getFont().getName();
            boolean isBold = fontName.toLowerCase().contains("bold") || text.getFont().getFontDescriptor() != null && text.getFont().getFontDescriptor().getFontWeight() > 500;
            System.out.printf("[%s] font=%s, size=%.1f, isBold=%b\n", text.getUnicode(), fontName, text.getFontSizeInPt(), isBold);
        }
    }

    public static void main(String[] args) {
        if (args.length < 1) {
            System.out.println("Uso: java -cp ... PDFInspector <archivo.pdf>");
            return;
        }
        try (PDDocument document = PDDocument.load(new File(args[0]))) {
            PDFInspector inspector = new PDFInspector();
            inspector.setSortByPosition(true);
            inspector.setStartPage(1);
            inspector.setEndPage(1);
            System.out.println("--- Inspeccionando PDF: " + args[0] + " ---");
            inspector.writeText(document, new java.io.OutputStreamWriter(System.out));
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
