import java.awt.*;
import java.io.*;
import javax.swing.*;
import javax.swing.text.*;  
  
public class ATMHostPanel   extends   ATMHostLogOut /* JPanel */ implements Runnable {

  private            BufferedReader             din,
                                                der;
  private                   boolean      endOfStream = false;
  private                       int       SLEEP_TIME = 50;
  private                    String              cmd = null;
  private                   Process             proc = null;
  private                    Thread           thread = null;  // Thread for self 

 ATMHostPanel () {
  }

 ATMHostPanel (int  maxLog,boolean islogTest,boolean islogInfo ){
 super( maxLog, islogTest, islogInfo);
 } 

 public void start (String cmd) {
  try {
   this.proc = Runtime.getRuntime().exec(cmd);
   // copy input and error to the output stream
   this.din = new BufferedReader(new InputStreamReader(proc.getInputStream()));
   this.der = new BufferedReader(new InputStreamReader(proc.getErrorStream()));
   if (this.thread == null ) {
     this.thread = new Thread(this,cmd);  //Create Thread for
	 this.thread.setPriority(Thread.MIN_PRIORITY);
     this.thread.start();
    }//end if
  }catch(Exception e) { 
   System.err.println(e); 
  }
 }

public void kill() {
    if (this.proc != null ){
     try {
       proc.destroy();
	   proc.waitFor();
	   endOfStream = true; 
	   this.thread = null;
       appendLogSystem("I kill this test process");
      }catch (Exception e ){
        System.out.println("Process" + e);  
       };
    }//end if 

 }

 /**
  *   Mandatory from interface Runnable (Thread)
  */ 
 public void run() {
  try {
   try {
     while (!endOfStream) {
      pumpStream();
      Thread.sleep(SLEEP_TIME);
	//  Thread.yield();
     }
    }catch (InterruptedException ie) {}
   din.close();
  } catch (IOException ioe) {}
 }


private  void pumpStream() throws IOException {
  String  line,eline;
  if (!endOfStream) {
    try{
	 if (din.ready()){
	    line = din.readLine();
      if (line != null){
        appendLogTest(line);	 
        appendLogSystem(line); 
       }else{endOfStream = true;};
     }//end if din
 
    while (der.ready()) {
	   eline = der.readLine();
	  if (eline != null){ 
       appendLogError(eline);
	   }else{ endOfStream = true; }
	}//end if   
	  
     }catch (Exception e){
          System.out.println(e);
     }
  }
 }

protected void finalize() throws Throwable {
  // Wait for everything to finish
  
   if (this.proc != null ){
      proc.destroy();
	  proc.waitFor();
     }
  super.finalize();
 } 

 



}
