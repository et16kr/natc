import java.io.*;
import java.util.*;
import javax.swing.JTable;
import javax.swing.table.*;
import javax.swing.*;
import java.util.*;


import java.awt.event.WindowAdapter;
import java.awt.event.WindowEvent;

import java.*;

public class JTableTDX extends JTable {
public                  String     TableName;
private             TableModel     dataModel;    // Data model internal TableModel obj
protected           aVectorTDX          data;
 
JTableTDX (String testCase, String testTDX){
  super();
  
  TableName = testCase;
  data = new aVectorTDX(TableName, testTDX);                 // Get data from Files
  setLayout(null);
  
  TableSorter  sorter =  new TableSorter( new AbstractTableModel() {
     public int     getColumnCount()                {return data.getColumnCount();}
     public int     getRowCount()                   {return data.size(); }
     public Object  getValueAt(int row, int col)    {return data.getValueAt(row,col);}
     public String  getColumnName(int col)          {return data.getColumnName(col);}
     public Class   getColumnClass(int col)         {return data. getColumnClass(col);}
     public boolean isCellEditable(int row, int col){return false;}
     public void    setValueAt(Object aValue, int row, int column) {;}
    }// end of  Table Model OBJECT
  );
  
  /* Vi are sorted now by TimeStamp  */

  sorter.sortByColumn(0);
  initializeLocalVars();
  setModel(sorter);
  updateUI();
  sorter.addMouseListenerToHeaderInTable(this);            // Add Handle for sort by click mouse 
 }

}//end JTableTDX 
