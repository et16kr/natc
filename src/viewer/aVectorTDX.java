/*
    aVectorTDX ALTIBASE ltd.
 */

import java.io.*;
import java.util.*;


public class aVectorTDX extends aVector {
 
 protected       String     TestCase;

 public  static     int       q_prc;        // Counter of process 
 private           long      min_ts;        // min  time stamp ( zero point )
 private           long     last_ts;        // last time stamp
 protected StringTokenizer     stok;        // Object for tocanize string

 aVectorTDX() { 
  super();
  min_ts   = 0x7fffffffffffffffL;    // Set max long
  last_ts  = 0;
  q_prc    = 0;        // Strahge like Short(0) - don't work ?!!
 } 



 public aVectorTDX(String TC, String TDX)
   {
    super();
    min_ts   = 0x7fffffffffffffffL;    // Set max long
	last_ts  = 0;
	q_prc    = 0;        // Strahge like Short(0) - don't work ?!!
			
    TestCase = TC;  
  try {    /* Tokonize TDX file to aVector tdx  */
       String atc_home = System.getProperty("ATC_HOME");
       String atc_work = System.getProperty("ATC_WORK");
	   
     if ( (atc_home  == null )||(atc_work == null) ) {
	    System.err.println("ERROR: I cant detect $ATC_HOME or $ATC_WORK !");
	    System.err.println("!! may be you forget -DATC_HOME=$ATC_HOME or/and -DATC_WORK=$ATC_WORK !!\n");
	    System.exit(1);
	   }
/* -------------------  Detect place of *.out/*.lst logick --------------------------   */
	String f_name_out  = TestCase;
	String f_name_bas  = TestCase;
    String f_name_tdx  = TDX;

    /*
    int s_indx = TestCase.lastIndexOf(".");
    if (s_indx != -1 )
     {
       f_name_bas  = TestCase.substring(0,s_indx);
	 }
	 else
	 {
	   f_name_out = f_name_bas + ".out";
	 }
     */
 
	File   file;

    /* Without extension think it *.out file  */
    
    if ( f_name_out.endsWith(".out") )    // for *.out in current dir   // 
	 {
	     file = new File(f_name_out);
	  if ( file.canRead() )  // Check access for local *.out & *.tdx file
	   { 
	     file = new File( f_name_tdx );
		 if ( !file.canRead()) 
		  {
		   System.err.println("ERROR: I can't read file " + f_name_tdx );
		   System.exit(1);
		  }
     	}
	   else // Check for $ATC_HOME/work/DF dirs read file 
	    {
//	      String sVal = "A" +  System.getProperty("atc.altibase.version","3").substring(0,1) + "_" + System.getProperty("atc.altibase.bit","XX") ;
          /*
	      f_name_out = f_name_bas + "_" + sVal + ".out";
          f_name_tdx = f_name_bas + "_" + sVal + ".tdx";
          */
		  file = new File(f_name_out);
		  if ( file.canRead() ) // Check access to file 
		   {
             file = new File( f_name_tdx );
        	 if ( !file.canRead())
          	  {
               System.err.println("ERROR: I can't read file " + f_name_tdx );
               System.exit(1);
              }
  		   }
           else // I cant Find any file 
           {              
             System.err.println("ERROR: I can't read file " + f_name_out );
             System.exit(1);
           }
	    }
	 }
	 else 
	 if  ( f_name_out.endsWith(".lst") ) // for ATC_HOME/LS in lst case //
	   {  
	    //String sVal = "A" +  System.getProperty("atc.altibase.version","3").substring(0,1) + "_" + System.getProperty("atc.altibase.bit","XX") ;
		
        /*
	    f_name_out = f_name_bas+ "_" + sVal + ".lst";
	    f_name_tdx = f_name_bas+ "_" + sVal + ".tdx";
        */

          file = new File(f_name_out);
          if ( file.canRead() ) // Check access to file
           {
             file = new File( f_name_tdx );
             if ( !file.canRead())
              {
               System.err.println("ERROR: I can't read file " + f_name_tdx );
               System.exit(1);
              }
           }
           else // I cant Find any file
           {
             System.err.println("ERROR: I can't read file " + f_name_out );
             System.exit(1);
           }
       }
	  else 
	   {
         System.err.println("ERROR: File shold have syffix *.lst or *.out");
         System.exit(1);
       }

/*   ------------------------------------------------------------------------  */
   	 TokenizeTDXStreams( new File(f_name_tdx), new File( f_name_out));
	 
    } catch(Exception ioe) {
      System.err.println("ERROR StreamToken:" + ioe.toString());
    }
  /* -- remove mark unVisable line from Data --  */	
  this.removeMarkUnVisable();	
 }

 public void TokenizeTDXStreams (File in_tdx,File in_out) {
  try{  
   this.TokenizeTDX(new BufferedReader( new FileReader(in_tdx)));
   this.TokenizeOUT(new BufferedReader( new FileReader(in_out)));
   }catch (Exception e){
   System.err.println(e);
   }
 }//end TokenizeTDXStreams


 /*  get all rows present from tdx if false or filtered if true  */

 public void removeMarkUnVisable() {

    TimeStampIdx    rw;
	int   refEnd   = 0;

    for (int i = 0 ; i < this.size();i++ ){
      rw = (TimeStampIdx)this.get(i);
      if (rw != null)
      {
          if (rw.visable){
	          this.elementData[refEnd] = rw ;  
	          refEnd++;
          }else{
	          this.elementData[refEnd]=null;
	      }//end if
      }
    }//end for
  this.elementCount = refEnd + 1;	
 }//end  get_tdx; 


///////////////////////////////

 private void TokenizeTDX(BufferedReader is)  {
   TimeStampIdx    ts_idx; 
  try
   {
	for (int x=0; true; x++ ) // Not EOF for TDX
      {
 /// get line 	  
	   try 
	     { 
	      ts_idx = new TimeStampIdx(is.readLine());
          
	     }
		catch (Exception e) 
		 {
		  // Stop readLine if null EOF same == null		 
		  break; 
		 };
         // Detect min time_stamp
		 if ( ts_idx.value() < this.min_ts )
          {
          // System.out.println(">>" + this.min_ts + "<<"+ tdx.value() + "<< "  );
           this.min_ts   = ts_idx.value();
           this.last_ts  = this.min_ts;
          }
         int  r_idx = ts_idx.idx_x;
		 this.add(r_idx,ts_idx);
              
	  // System.out.println(idx_x + " size " +  v_tdx.size() );
///	END SPLIT line 

	  }//for-x
	 }//try-0
    catch(Exception e)
    {
      System.err.println("ERR in TokenizeTDX:" + e.toString());
    } //cath
  /* Normolize TDX point */
  //print_tdx();
  normTimeStamp();
  //print_tdx();
 }//TokenizeTDX

private void normTimeStamp ()
 {
 // new obj for set to tdx
 TimeStampIdx       v_row = null;                         // New row for array
 TimeStampIdx       p_row = new TimeStampIdx(); 

 // Scan by rows tdx aVector 
 
 long before_last_ts = min_ts;
 long before_delta = 0;
 for (int x=0; x < this.size(); x++ )
    {
      v_row = (TimeStampIdx)this.get(x);

      if (  v_row != null )
       {
        p_row =  v_row;
		// norm 
        last_ts = v_row.value();

        // Set normalize time         
        if (before_last_ts == last_ts)
        {
            before_delta++;
        }
        else
        {
            before_delta = last_ts - min_ts;
            before_last_ts = last_ts;
        }
		v_row.value(before_delta);
        //System.out.println(">>>1>(" + v_row.stm_type + ":" + x + ")" + last_ts + " :: " + (last_ts-min_ts) + "<<<<");
        this.set(x,v_row);                           // Set to tdx 
       } 
      /*
      else
       {   
         // increase for save order for multistring out from select
		//++last_ts;
		// allocate new row
        before_delta ++;
        v_row = new TimeStampIdx(before_delta);  // Make copy with norm 
		v_row.proc_no = p_row.proc_no ;        		// Same process
		v_row.stm_type= p_row.stm_type;        		// Same Type 
		v_row.idx_x   = x			  ;        		// Set current index
        System.out.println(">>>2>(" + v_row.stm_type + ":" + x + ")" + last_ts + " :: " + (last_ts-min_ts) + "<<<<");
       }
       */
     }

 }


private void TokenizeOUT(BufferedReader is)
 {
  TimeStampIdx       v_row = null;                         // New row for array
  TimeStampIdx       p_row = null;                         // New row for array
        String         str = null;                         // String read buffer
        long         delta_ts = 0;
 //print_tdx();
  int      proc_no = 0;
  try /* Execute for finish file EOF Exception  */
   {
    for (int x=1; true; x++ ) // Not EOF for TDX
      {
       try  // try readLine 
         {
          str = is.readLine();
          if ( str == null ) { break; } 
         }
        catch(EOFException e){ break; /* EOF breack */ }

        if ( str.startsWith("$P") )
          {
           proc_no = Integer.parseInt(str.substring(2,str.indexOf('>')));
		   if (proc_no > q_prc ){ q_prc = proc_no;}
          }
         
        if (this.size() > x )
         {
           v_row = (TimeStampIdx)this.get(x);
           if (v_row == null)
           {
               if (p_row != null && proc_no != p_row.proc_no)
               {
                   delta_ts = 0;
               }
               v_row = new TimeStampIdx(++delta_ts);  // Make copy with norm 
//System.out.println("new " + x + " delta " + delta_ts + " : " + str);
               if (p_row != null)
               {
		           v_row.proc_no = p_row.proc_no ;        		// Same process
		           v_row.stm_type= p_row.stm_type;        		// Same Type 
               }
               else
               {
		           v_row.proc_no = 0 ;        		// Same process
		           v_row.stm_type= 'C';        		// Same Type 
               }
		       v_row.idx_x   = x			  ;        		// Set current index
           }
           else
           {
               if (proc_no != v_row.proc_no)
               {
                   delta_ts = 0;
               }
//System.out.println("get " + x + " delta " + delta_ts + " time " + v_row.value() + " : " + str);
               if (delta_ts < v_row.value())
               {
                   delta_ts = v_row.value();
               }
               else
               {
                   //delta_ts = v_row.value();
                   v_row.value(++delta_ts);
               }
               p_row =  v_row;
           }
		   proc_no = v_row.proc_no;
         }
         else 
         {
//		   System.out.println("new " + x);
          v_row = new TimeStampIdx();
         }
          
  /*  test and set visable for TDX_View utilite   */
  //  if (str.startsWith("+--") ) {v_row.visable = false;} else {v_row.visable = true;};
  

      //v_row.visable = !str.startsWith("+--"); 			    // for string beginin '+---' 
      if ( str.startsWith("+--") )
      {
          str = "";
      }
      
	  if ( str.startsWith("| ") ){                          // Remove lead "| " and set color
	     str = "    " + str.substring(2);

       }
  /* ------------------------------------------- */
     v_row.setOUT(proc_no,str);
     this.add(x,v_row);          

      //System.out.println(x + " delta " + delta_ts + " : " + str);
      }//for-x 
   }//try-0
   catch(Exception e)
   {
      System.out.println("ERROR in TokenizerOUT:" + e.toString());
   } // cath
   //    print_tdx(); 
 } // TokenizeOUT


public void print_tdx (){
   String          str;
   TimeStampIdx  v_row;
   for (int x=0; x < elementCount; x++ )
    {
      v_row = (TimeStampIdx)this.get(x);
      System.out.print(":" + x + " " );
      if (  v_row != null )
       {
        System.out.print(
		x + "\t"
        + v_row.visable  + "\t"
		+ v_row.value() + " idx:"
		+ v_row.idx_x + "\tP"
	    + v_row. proc_no + " "
        + v_row.getTypeOfcmd () + " " 
		);
        for (int y=0; y < v_row.row.size(); y++ )
        {
         str = (String)v_row.get(y).toString();
         if (str == null) {str = "                   "; }; 
         System.out.print(" " + str );
         }
        } // if null

     System.out.println();
    }
  }// print_tdx

 public Object get(int row ,int  col){   // Extended for get by row/col from table
  TimeStampIdx p_row = (TimeStampIdx)this.get(row);
  return  p_row.get(col);
 }

//* For interface to AbstractTableModel *//
 public int    getColumnCount(){ return this.q_prc + 2;       }

 public int    getRowCount()   { return this.elementCount +1; }
 
 public Object getValueAt(int row, int col){
    TimeStampIdx p_row = (TimeStampIdx)this.get(row);
	  return  p_row.get(col);
  }
  
 public String   getColumnName(int col) {
      if (col == 0 ){ return "Time";
	   }else{            return "Process P" + (col - 1);
	  }
 } // end getColumnName(int column)
 
 public Class   getColumnClass(int col){return getValueAt(0,col).getClass();}
 
 public boolean isCellEditable(int row, int col){return false;}
 public void setValueAt(Object aValue, int row, int column) {;}


}////////////////////////////END

