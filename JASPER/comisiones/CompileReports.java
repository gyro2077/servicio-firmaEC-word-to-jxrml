import net.sf.jasperreports.engine.JasperCompileManager;

public class CompileReports {
    public static void main(String[] args) {
        try {
            JasperCompileManager.compileReportToFile("pago.jrxml", "pago.jasper");
            JasperCompileManager.compileReportToFile("pagoVisa.jrxml", "pagoVisa.jasper");
            JasperCompileManager.compileReportToFile("pagoPrueba.jrxml", "pagoPrueba.jasper");
            JasperCompileManager.compileReportToFile("anticipoMod1.jrxml", "anticipoMod1.jasper");
            JasperCompileManager.compileReportToFile("vMemoAnticipo.jrxml", "vMemoAnticipo.jasper");
            JasperCompileManager.compileReportToFile("oficioPago.jrxml", "oficioPago.jasper");
            JasperCompileManager.compileReportToFile("oficioPago1.jrxml", "oficioPago1.jasper");
            JasperCompileManager.compileReportToFile("oficioPagoAntesTcrnValencia.jrxml",
                    "oficioPagoAntesTcrnValencia.jasper");
            System.out.println("ALL Compiled successfully.");
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
