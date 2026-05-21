/* ********************************************************************
 * Copyright 1999-2002, ALTIBase Corporation or its subsidiaries.
 * All rights reserved.
 * ********************************************************************
 */

 /* *******************************************************************
  * Obect for read atc.conf by $ATC_HOME enveroument one shold be pass  
  * to java -DATC_HOME=$ATC_HOME parametr 
  *
  *********************************************************************
  */

import java.io.*;
import java.util.*;


public class PropertiesATC   extends Properties {

 private                String   homeDir   =             null;    // $ATC_HOME dir 
 private                String   workDir   =             null;    // $ATC_WORK dir
 private                String   confFile  =  "conf/atc.conf";    // Set to conf file on $ATC_HOME
 private                String   versFile  =  "altibase.info";    // File represents for Altibase info 

 /**
  * Create an property list constructors 
  */


 PropertiesATC () {
   this(null,null);
  }///

  PropertiesATC (String confFile){
   this(confFile,null);
  }///

  PropertiesATC ( String confFile,  String   versFile) {
   super();

  /*-  ATC_HOME   if not pass by -DATC_HOME use full path  -*/  
   homeDir  = System.getProperty("ATC_HOME");
   homeDir = !(homeDir == null ) ? homeDir + "/" : "" ;
  
   /*-  ATC_WORK  if not pass by -DATC_WORK use full path  -*/
   workDir  = System.getProperty("ATC_WORK");
   workDir = !(workDir == null ) ? workDir + "/" : "" ;
		 

  
   this.confFile = (confFile == null) ? homeDir + this.confFile       // Set default file
                                      : homeDir +      confFile;      // Set passing parametr 
				 
   this.versFile = (versFile == null) ? workDir + this.versFile       // Set default file
                                      : workDir +      versFile;      // Set passing parametr
   this.tokenizeVersionFile();                                        // Tokenize and set to System properties
  
  try{ this.load();
   }catch (IOException e) { 
    System.err.println(e);
	System.exit(1);
	}
  
 }///

 public synchronized void load () throws IOException {
    FileInputStream in = new FileInputStream(confFile);        // Load from atc.conf file
    super.load(in);
  }///end load   

  public synchronized void load (String fileName) throws IOException {
    this.confFile = fileName;
    FileInputStream in = new FileInputStream(confFile);        // Load from atc.conf file
    this.load(in);
  }//end load 2
 
  public synchronized void save () { 
   String header = 
      "######################################################################\n"
    + "# Copyright 1999-2002, ALTIBase Corporation or its subsidiaries.\n"
    + "# All rights reserved.\n"
    + "# ATC  Configuration file  \n"
    + "#######################################################################";
  try{
   FileOutputStream  out = new FileOutputStream(confFile);
   store(out,header); 
   }catch(IOException e){
   }       
  }//end save 

  public synchronized void save (String fileName){
   this.confFile = fileName;
   this.save(); 
  }//end save 2

  /* export proerties to global System Properties for all utilites  */
  public synchronized void exportToSystem(){
    String key = null;
    String val = null;
    for (Enumeration e =  super.propertyNames() ; e.hasMoreElements() ; ) {
      key   = (String)e.nextElement();
      val   =  super.getProperty(key);   
      key   = "atc." + key;
      System.setProperty(key,val);
    }//end for 
   }//end exportToSystem

  /**
   *   Tokenize Strin from $ATC_HOME/altibase.info like
   *   "version 2.5.3 SPARC_SOLARIS_2.7-64bit-compat5-2.5.3-release
   *    (sparc-sun-solaris2.7) May 21 2002 00:18:13" 
   *   To:
   *      atc.altibase.version      = 2.5.3
   *      atc.altibase.platform     = sparc-sun-solaris2.7
   *      atc.altibase.release      = SPARC_SOLARIS_2.7-64bit-compat5-2.5.3-release
   *      atc.altibase.bit          = 64
   *      atc.altibase.release.date = May 21 2002 00:18:13
   */

  public synchronized void tokenizeVersionFile(){this.tokenizeVersionFile(this.versFile); }
  public synchronized void tokenizeVersionFile (String versFileName){
  try{
    /*
     DataInputStream in =
               new DataInputStream(
                   new BufferedInputStream(
                       new FileInputStream(
                           versFileName)));
    */				   
    BufferedReader in = new  BufferedReader(
	                     new FileReader(versFileName));
   // Read and Tokenize jast one line now //
   StringTokenizer stok = new StringTokenizer(in.readLine()); 
   String sTail = "";
    for (int y = 0; stok.hasMoreTokens(); y++ )
    {
     String val = (String)stok.nextElement();
     switch (y)
          {
           case  0   :break; 
           case  1   :{ setProperty("altibase.version",val);
                      break;
                     }
           case  2   :{ setProperty("altibase.release",val);
                      StringTokenizer stok2 = new StringTokenizer(val, "-");
                      for (int inx = 0; stok2.hasMoreTokens(); inx++)
                      {
                          String subval = (String)stok2.nextElement();
                          switch (inx)
                          {
                              case 0  : break;
                              case 1  : 
                                        setProperty("altibase.bit", subval.substring(0,2));
                                        break;
                              case 2  : break;
                              case 3  : break;
                          }
                      }
                      break;
                     }  
           case  3   :{ setProperty("altibase.platform",val);
                      break;                       
                      }
           default: sTail = sTail + " " + val;
          }//switch-y
       }//for-y
      setProperty("altibase.release.date",sTail);        
      in.close();
    }catch (Exception e) {
     System.err.println(e);
   }//end try
 }//end  tokenizeVersionFile



 /* --------------- main test method ---------------- */

 public static void main (String args[]){
  
  if (args.length == 0 ){
   System.err.println("ERROR: shold be parametr");
   System.exit(1);
   }

  PropertiesATC atc_conf;
  try{
   atc_conf  = new PropertiesATC (args[0]);
  
   atc_conf.exportToSystem();                  //Set to System enviroument properties
   
   atc_conf.tokenizeVersionFile();              // Test tokenize altibase info file
   Properties
        prop = System.getProperties();


		
   String key = null;
   for (Enumeration e =  prop.propertyNames() ; e.hasMoreElements() ; ) {
      key =  (String)e.nextElement();
      System.out.println(key + "=" +  prop.getProperty(key) );
     }
   atc_conf.save("tdxview.properties");

   }catch(Exception e) {
   System.err.println("ERROR: main>>> " + e );
   System.exit(1); 
  } 
 }//end main







}//end PropertiesATC class declaration
