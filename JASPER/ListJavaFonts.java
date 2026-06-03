import java.awt.GraphicsEnvironment;
public class ListJavaFonts {
    public static void main(String[] args) {
        try {
            String[] fontNames = GraphicsEnvironment.getLocalGraphicsEnvironment().getAvailableFontFamilyNames();
            System.out.println("--- Fonts available to AWT (" + fontNames.length + ") ---");
            for (int i = 0; i < Math.min(fontNames.length, 50); i++) {
                System.out.println(" - " + fontNames[i]);
            }
            if (fontNames.length > 50) {
                System.out.println(" ... and " + (fontNames.length - 50) + " more");
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
