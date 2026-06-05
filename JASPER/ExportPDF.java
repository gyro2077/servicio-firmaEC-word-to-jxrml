import java.util.HashMap;
import net.sf.jasperreports.engine.JasperFillManager;
import net.sf.jasperreports.engine.JasperPrint;
import net.sf.jasperreports.engine.JasperExportManager;
import net.sf.jasperreports.engine.JREmptyDataSource;

/**
 * Exportador de PDF compatible con JasperReports 5.x, 6.x y 7.x.
 * Usa solo System.setProperty (API estándar Java) en lugar de
 * JRProperties que fue eliminada en JR 7.x.
 */
public class ExportPDF {
    public static void main(String[] args) {
        if (args.length < 2) {
            System.out.println("Uso: java ExportPDF <archivo.jasper> <salida.pdf>");
            System.exit(1);
        }
        
        String jasperFile = args[0];
        String pdfFile    = args[1];
        
        try {
            // Propiedades de sistema — compatibles con JR 5, 6 y 7
            System.setProperty("net.sf.jasperreports.awt.ignore.missing.font", "true");
            System.setProperty("net.sf.jasperreports.default.font.name",       "Arial Narrow");

            System.out.println("Llenando reporte: " + jasperFile);
            JasperPrint jasperPrint = JasperFillManager.fillReport(
                jasperFile,
                new HashMap<>(),
                new JREmptyDataSource()
            );
            
            System.out.println("Exportando a PDF: " + pdfFile);
            JasperExportManager.exportReportToPdfFile(jasperPrint, pdfFile);
            
            System.out.println("✓ Exportación exitosa a PDF: " + pdfFile);
        } catch (Exception e) {
            System.err.println("ERROR al exportar a PDF: " + e.getMessage());
            e.printStackTrace();
            System.exit(1);
        }
    }
}
