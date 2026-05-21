import java.io.*;
import java.awt.*;
import java.awt.event.*;
import javax.swing.*;
import javax.swing.table.TableColumn;

public class  TDX_View   extends JFrame {

TDX_View (String TC, String TDX) 
   {
     super("TDX_View: " +  TC 
                        + "     ALTIBASE: " +  System.getProperty("atc.altibase.release","unknow")
                        + " Compile Date: " +  System.getProperty("atc.altibase.release.date","unknow"));

     try  {
       UIManager.setLookAndFeel(UIManager.getSystemLookAndFeelClassName());
     }
     catch(Exception e) {
     }

    Container c = getContentPane();

    WindowListener wndCloser = new WindowAdapter(){
      public void windowClosing(WindowEvent e){
        System.exit(0);
       }
    };
	addWindowListener(wndCloser);

 /* set size for table  */
    JTableTDX  ttdx = new JTableTDX(TC, TDX);
	
//  TableColumn column = 
  ttdx.getColumnModel().getColumn(0).setMaxWidth(70);;
//  column.setPreferredWidth(80);
//  column.setMinWidth(50) ;
//  column.setMaxWidth(100);
  for (int i = 1; i < ttdx.getColumnCount(); i++){
      ttdx.getColumnModel().getColumn(0).setMinWidth(100) ;
    }
	
   getContentPane().add( new JScrollPane(ttdx));
   pack();
   setSize(860, 640);
   setVisible(true);
  }





 public static void main(String[] args) {


  if (args.length == 0 ) {
    System.err.println("ERROR: should be parametr!");
    System.exit(1);
   }

		
   /*- Get common properties and save it  -*/
 PropertiesATC  prop = new PropertiesATC();         // by Default check $ATC_HOME/conf/atc.conf file
     prop.exportToSystem();                         // Export to Systems enveroumet properties
      new TDX_View(args[0], args[1]);
  }
  
}
      


