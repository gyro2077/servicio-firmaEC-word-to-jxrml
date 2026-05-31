import net.sf.jasperreports.engine.JasperCompileManager;

public class CompileJasper {
    public static void main(String[] args) {
        if (args.length < 1) {
            System.out.println("Uso: java CompileJasper <archivo.jrxml>");
            System.exit(1);
        }
        
        String jrxmlFile = args[0];
        String jasperFile = jrxmlFile.replace(".jrxml", ".jasper");
        
        try {
            System.out.println("Compilando: " + jrxmlFile);
            JasperCompileManager.compileReportToFile(jrxmlFile, jasperFile);
            System.out.println("✓ Compilado exitosamente: " + jasperFile);
        } catch (Exception e) {
            System.err.println("ERROR al compilar: " + e.getMessage());
            e.printStackTrace();
            System.exit(1);
        }
    }
}
