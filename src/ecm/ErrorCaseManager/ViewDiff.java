package ErrorCaseManager;

import java.awt.*;
import java.awt.event.*;
import javax.swing.event.TreeSelectionListener;
import javax.swing.event.TreeSelectionEvent;
import javax.swing.*;
import javax.swing.tree.*;
import java.io.*;

/**
 * <p>Title: </p>
 * <p>Description: </p>
 * <p>Copyright: Copyright (c) 2002</p>
 * <p>Company: </p>
 * @author unascribed
 * @version 1.0
 */

public class ViewDiff extends JPanel {

  
  BorderLayout borderLayout1 = new BorderLayout();
  JScrollPane jScrollPane1 = new JScrollPane();
  JTree jTree1;
  DefaultMutableTreeNode mErrRoot;
  DefaultMutableTreeNode mErrCurrentTS;
  DefaultMutableTreeNode mCurrentTS;
  DefaultMutableTreeNode mCurrentTC;
  Process viewDiff;
  Process tdxView;
  String  mServer;
  int     mCntTS=0;
  int     mCntTC=0;

  String  mOsTarget;

  FindLstOut findFile = new FindLstOut();

  //Construct the frame
  public ViewDiff() {
    enableEvents(AWTEvent.WINDOW_EVENT_MASK);
    try {
      jbInit();
    }
    catch(Exception e) {
      e.printStackTrace();
    }

    mOsTarget = System.getProperty("OS_TARGET");
  }

  public void killChild() {
    if (viewDiff != null) {
        viewDiff.destroy();
    }
  }
  public void expandRoot()
  {                   
      jTree1.collapseRow(0);
      jTree1.expandRow(0);
  }  
  public int getCntTS()
  {
      return mCntTS;
  }
  public int getCntTC()
  {
      return mCntTC;
  }
  public void reset()
  {
      mCntTS = 0;
      mCntTC = 0;
      mErrRoot.removeAllChildren();
  }
  public void setServer(String a_server) {
    mServer = new String(a_server);
     mErrRoot = new DefaultMutableTreeNode(a_server);
    // below reset Tree for Added 
    jTree1.setModel( new DefaultTreeModel( mErrRoot ));
  }
  public void runTDX() 
  {
    String tree_node_string;
    String temp;

    if (mCurrentTC != null)
    {
        tree_node_string = (String)mCurrentTC.getUserObject();
        int pos = tree_node_string.indexOf(':');
        String t_case = tree_node_string.substring(pos+1);
        if (mCurrentTC.isLeaf()) {
            try 
            {
                findFile.getAllEnv();

                // altibase.info 파일을 읽어서
                // lst, out의 파일 이름과 path를 구성하는 정보를 가져온다.
                findFile.readFile();
                findFile.findPathName( t_case );

                String tdx_name = findFile.tdxName;

                if ( mOsTarget.equals( "WIN_NT" ) )
                {

                    if (!mServer.equals("localhost")) 
                    {
                        tdxView = Runtime.getRuntime().exec("rsh "+mServer+"bash tdxview " + tdx_name );
                        System.out.println("rsh "+mServer+" tdxview " + tdx_name );
                    } 
                    else 
                    {
                        tdxView = Runtime.getRuntime().exec("bash tdxview " + tdx_name );
                        System.out.println(" tdxview " + tdx_name );
                    }
                }
                else
                {
                    if (!mServer.equals("localhost")) 
                    {
                        tdxView = Runtime.getRuntime().exec("rsh "+mServer+" tdxview " + tdx_name );
                        System.out.println("rsh "+mServer+" tdxview " + tdx_name );
                    } 
                    else 
                    {
                        tdxView = Runtime.getRuntime().exec(" tdxview " + tdx_name );
                        System.out.println(" tdxview " + tdx_name );
                    }
                }
            }
            catch(java.io.IOException ex) 
            {
                 ex.printStackTrace();
            }
        }
    }
  }

  public void runCopy()
  {
    String tree_node_string;
    if (mCurrentTC != null)
    {
        tree_node_string = (String)mCurrentTC.getUserObject();
        int pos = tree_node_string.indexOf(':');
        String t_case = tree_node_string.substring(pos+1);
        if (mCurrentTC.isLeaf()) {
            try
            {
                findFile.getAllEnv();

                // altibase.info 파일을 읽어서
                // lst, out의 파일 이름과 path를 구성하는 정보를 가져온다.
                findFile.readFile();
                findFile.findPathName( t_case );

                String lst_name = findFile.lstName;
                String out_name = findFile.outName;

                if (!mServer.equals("localhost"))
                {
                    tdxView = Runtime.getRuntime().exec("rsh "+mServer+ " cp " + out_name + " " + lst_name );
                    System.out.println("rsh "+mServer+ " cp " + out_name + " " + lst_name );
                }
                else
                {
                    tdxView = Runtime.getRuntime().exec(" cp " + out_name + " " + lst_name );
                    System.out.println(" cp " + out_name + " " + lst_name );
                }
            }
            catch(java.io.IOException ex)
            {
                 ex.printStackTrace();
            }
        }
    }
  }	
  //Component initialization
  private void jbInit() throws Exception  {
    this.setLayout(borderLayout1);
    this.add(jScrollPane1, BorderLayout.CENTER);
    mErrRoot = new DefaultMutableTreeNode("Error Cases");
    DefaultTreeModel errModel = new DefaultTreeModel(mErrRoot);

    jTree1 = new JTree(errModel);
    jTree1.putClientProperty("JTree.lineStyle", "Angled");
    jTree1.setEditable(false);
    jTree1.getSelectionModel().setSelectionMode(TreeSelectionModel.SINGLE_TREE_SELECTION);

    ToolTipManager.sharedInstance().registerComponent(jTree1);

    //Listen for when the selection changes.
    jTree1.addTreeSelectionListener(new TreeSelectionListener() {
        public void valueChanged(TreeSelectionEvent e) {
            DefaultMutableTreeNode node = (DefaultMutableTreeNode)
                               jTree1.getLastSelectedPathComponent();

            if (node == null) return;


            String tree_node_string = (String)node.getUserObject();

            jTree1.setToolTipText(tree_node_string);

            int pos = tree_node_string.indexOf(':');
            String t_case = tree_node_string.substring(pos+1);
            mCurrentTC = null;
            if (node.isLeaf()) {
                mCurrentTC = node;
                mCurrentTS = (DefaultMutableTreeNode)mCurrentTC.getParent();
                try {
                    findFile.getAllEnv();

                    // altibase.info 파일을 읽어서
                    // lst, out의 파일 이름과 path를 구성하는 정보를 가져온다.
                    findFile.readFile();
                    findFile.findPathName( t_case );

                    String lst_name = findFile.lstName;
                    String out_name = findFile.outName;

                    killChild();

                    if ( mOsTarget.equals( "WIN_NT" ) )
                    {
                        viewDiff = Runtime.getRuntime().exec("tkdiff "+ lst_name + " " + out_name );
                        System.out.println(" tkdiff "+ lst_name + " " + out_name );
                    }
                    else
                    {
                        if (!mServer.equals("localhost")) {
                            viewDiff = Runtime.getRuntime().exec("rsh "+mServer+" tkdiff "+ lst_name + " " + out_name );
                            System.out.println("rsh "+mServer+" tkdiff "+ lst_name + " " + out_name );
                        } else {
                            viewDiff = Runtime.getRuntime().exec(" tkdiff "+ lst_name + " " + out_name );
                            System.out.println(" tkdiff "+ lst_name + " " + out_name );
                        }
                    }
                }catch(java.io.IOException ex) {
                    ex.printStackTrace();
                }
            }
        }
    });

    jScrollPane1.getViewport().add(jTree1, null);
  }

  public void putErrorInfo(String a_type, String a_err)
  {
    DefaultMutableTreeNode new_node = new DefaultMutableTreeNode(a_err);
    if ( a_type.equals("TS") )
    {
      mErrRoot.add(new_node);
      mErrCurrentTS = new_node;
      mCntTS++;
    }
    else
    {
      mErrCurrentTS.add(new_node);
      mCntTC++;
    }
  }
}
