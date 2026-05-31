import java.util.HashMap;
import net.sf.jasperreports.engine.JasperFillManager;
import net.sf.jasperreports.engine.JasperPrint;
import net.sf.jasperreports.engine.JasperExportManager;
import net.sf.jasperreports.engine.JREmptyDataSource;

public class ExportPDF {
    public static void main(String[] args) {
        if (args.length < 2) {
            System.out.println("Uso: java ExportPDF <archivo.jasper> <salida.pdf>");
            System.exit(1);
        }
        
        String jasperFile = args[0];
        String pdfFile = args[1];
        
        try {
            System.setProperty("net.sf.jasperreports.awt.ignore.missing.font", "true");
            net.sf.jasperreports.engine.util.JRProperties.setProperty("net.sf.jasperreports.awt.ignore.missing.font", "true");

            System.out.println("Llenando reporte: " + jasperFile);
            // Llenar con parámetros por defecto (HashMap vacío) y fuente de datos vacía
            JasperPrint jasperPrint = JasperFillManager.fillReport(jasperFile, new HashMap<>(), new JREmptyDataSource());
            
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
