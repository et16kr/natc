package ErrorCaseManager;

import javax.swing.*;
import java.awt.*;
import java.awt.event.*;
import java.io.*;

import ErrorCaseManager.*;

/**
 * <p>Title: </p>
 * <p>Description: </p>
 * <p>Copyright: Copyright (c) 2002</p>
 * <p>Company: </p>
 * @author unascribed
 * @version 1.0
 */


public class ErrorCaseManager {
    String mServer;
    
    static String mOsTarget;
    static String mAtcHome;

    Label mStatusLabel;
    Label mProgressLabel;
    Label mStatisticsLabel;

    static ViewDiff viewDiff;

    //Construct the application
    public ErrorCaseManager(String a_server) {
        mServer = new String(a_server);
    }
    protected void finalize() {
        System.out.println("The main is finalized...");
    }
    //Main method
    public static void main(String[] args) {

        boolean packFrame = false;
        final ErrorCaseManager ecm;
        //System.out.println("arg length =  "+args.length+" : "+args[0]);

        mOsTarget = System.getProperty("OS_TARGET");        
        mAtcHome = System.getProperty("ATC_HOME");

        if (args.length > 0)
        {
            ecm = new ErrorCaseManager(args[0]);
        }
        else
        {
            ecm = new ErrorCaseManager("localhost");
        }
        viewDiff = new ViewDiff();


        JFrame frameObj = new JFrame("Error Case List");
        frameObj.setSize(200, 400);
        try {
            //UIManager.setLookAndFeel(UIManager.getCrossPlatformLookAndFeelClassName());
            //UIManager.setLookAndFeel("com.sun.java.swing.plaf.windows.WindowsLookAndFeel");
            UIManager.setLookAndFeel(UIManager.getSystemLookAndFeelClassName());
            //System.out.println(UIManager.getSystemLookAndFeelClassName());
            //SwingUtilities.updateComponentTreeUI(viewDiff);
        }
        catch(Exception e) {
            e.printStackTrace();
        }
        //Validate viewDiffs that have preset sizes
        //Pack viewDiffs that have useful preferred size info, e.g. from their layout
        if (packFrame) {
            frameObj.pack();
        }
        else {
            frameObj.validate();
        }
        //Center the window
        Dimension screenSize = Toolkit.getDefaultToolkit().getScreenSize();
        Dimension frameObjSize = frameObj.getSize();
        if (frameObjSize.height > screenSize.height) {
            frameObjSize.height = screenSize.height;
        }
        if (frameObjSize.width > screenSize.width) {
            frameObjSize.width = screenSize.width;
        }
        frameObj.setLocation((screenSize.width - frameObjSize.width) / 2, (screenSize.height - frameObjSize.height) / 2);
        frameObj.setVisible(true);


        Container containerObj = frameObj.getContentPane();
        containerObj.add(viewDiff, BorderLayout.CENTER);
        frameObj.addWindowListener(new WindowAdapter() {
            public void windowClosing(WindowEvent e) {
                viewDiff.killChild();
                System.exit(0);
            }
        });

        JToolBar toolBar = new JToolBar();
        containerObj.add(toolBar, BorderLayout.NORTH);

        JButton tdxButton = new JButton("TDX");
        JButton loadButton = new JButton("LOAD");
        JButton copyButton = new JButton("out->lst");
        toolBar.add(tdxButton);
        toolBar.add(loadButton);
        toolBar.add(copyButton);

        tdxButton.addActionListener(new java.awt.event.ActionListener() {
          public void actionPerformed(ActionEvent e) {
            //System.out.println("TDX Button pushed...");
            viewDiff.runTDX();
          }
        });
        loadButton.addActionListener(new java.awt.event.ActionListener() {
          public void actionPerformed(ActionEvent e) {
            //System.out.println("LOAD Button pushed...");
            viewDiff.reset();
            ecm.runTest();
            viewDiff.expandRoot();
            ecm.setStatistics();
          }
        });

        copyButton.addActionListener(new java.awt.event.ActionListener() {
          public void actionPerformed(ActionEvent e) {
            //System.out.println("TDX Button pushed...");
             viewDiff.runCopy();
          }
        });

        Panel statusBar = new Panel(new BorderLayout());
        statusBar.setBackground(Color.lightGray);
        ecm.mStatusLabel = new Label("", Label.CENTER);
        ecm.mProgressLabel = new Label("", Label.LEFT);
        ecm.mStatisticsLabel = new Label("", Label.RIGHT);
        statusBar.add(ecm.mStatusLabel, BorderLayout.CENTER);
        statusBar.add(ecm.mProgressLabel, BorderLayout.WEST);
        statusBar.add(ecm.mStatisticsLabel, BorderLayout.EAST);

        containerObj.add(statusBar, BorderLayout.SOUTH);

        ecm.runTest();
        viewDiff.expandRoot();
        ecm.setStatistics();

        frameObj.show();
        frameObj.pack();
        frameObj.setVisible(true);
    }
    public void setStatistics()
    {
        int ts_cnt = viewDiff.getCntTS();
        int tc_cnt = viewDiff.getCntTC();

        mStatisticsLabel.setText("TS: "+ts_cnt+" TC: "+ tc_cnt);
    }
    public void runTest()
    {
        try {
            Process proc;
            if ( mOsTarget.equals( "WIN_NT" ) )
            {
                proc = Runtime.getRuntime().exec("perl " + mAtcHome + "/bin/getErrorCase.pl");
            }
            else
            {
                if (!mServer.equals("localhost")) {
                    proc = Runtime.getRuntime().exec("rsh "+mServer+" getErrorCase.pl");
                } else {
                    proc = Runtime.getRuntime().exec("getErrorCase.pl");
                }
            }
  
            BufferedReader br = new BufferedReader(new InputStreamReader(proc.getInputStream()));
            PrintStream ps = new PrintStream(System.out);
            String inLine = br.readLine();
            String errType;
            String errName;
            int pos;
            /*
            if (inLine == null) {
	            System.out.println("There is no Error Suite file.");
	            System.exit(-1);
            }
            */
            viewDiff.setServer(mServer);
            while(inLine != null) {
                //ps.println(inLine);
                //atm.display(inLine);
                pos = inLine.indexOf(':');
                errType = inLine.substring(0, pos);
                errName = inLine.substring(pos+1);
                System.out.println("type : "+errType+" name : "+errName);
                viewDiff.putErrorInfo(errType, errName);
                inLine = br.readLine();
            }
        }catch(java.io.IOException e) {
            System.out.println(e);
        }
    }

}
