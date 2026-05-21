/*
  TimeStampIdx - object for represent element on table TDX
  has method for manipulation with data
*/

import  java.*;
import  java.lang.*;
import  java.util.StringTokenizer;

class TimeStampIdx   extends   Number  {
// public     static final Class      TYPE = Class.getPrimitiveClass("long");
 protected			long	   		value; 	 // Internal    Time xNIX format   is   not full correct
 											 //	Becouse it  take and  truncate from TDX
 public 			 int 	  	  proc_no;   // Process No  for  time Stamp
 public			     int            idx_x;   // index   to  row  in table TDX 
 public				char         stm_type;   // Type of execution C - command,
 											 // 				  S - send to  chanal,
											 //					  R - read fro chanal,
 protected       aVector              row;   // Array of output line from TCxxx.out

 public 	     boolean          visable;   // Set visable this row or no 
											 
											 
/*  ******	Constructors for Time Stamp   ***** */
 public TimeStampIdx () 
  { 
   this.value   = 0x7fffffffffffffffL;   //   set max long type
   this.proc_no = 0;
   this.idx_x   = 0;
   this.row     = new aVector();
   this.visable = true;
  } 

 public TimeStampIdx (long value) 
  {
  this.value = value;
  this.row     = new aVector();
  this.visable = true; 
  }

 public TimeStampIdx (String str)
  {
   this.row      = new aVector();
   this.visable  = true;  
   
  StringTokenizer stok = new StringTokenizer(str,"\n\r|");   // String Tokenizer    
  String strV;
   
   for (int y = 0; stok.hasMoreTokens(); y++ )
    {
     strV =  stok.nextToken();
         switch (y)
          {
           case 0  :{  /*       Detect row index x      */
                     this.idx_x = Integer.parseInt(strV);
                     break;
                    }
           case 1  :{  /*		Detect stm Type  S/R/C	*/
                     this.stm_type = strV.charAt(0);  
 					 break;
 					}	
           case 2  :{// Detect process Number but can be ignore
                     this.proc_no = (int)Short.parseShort( strV.substring(1) ); 
                     break;
                    }
           case 3  :{/*  Time stamp trunk   from 10E-6		 */ 
                     this.value = (long)( (double)Double.parseDouble(strV) * 1000000 );
                     break;
                    }
           default: ;
          }//switch-y
         }//for-y
   /*
        System.out.println(
              + value  + " idx:"
              + idx_x + " P"
              + proc_no + " "
              + getTypeOfcmd () + " "
              );
   */
 
  }
  
 public    String getTypeOfcmd () {
    char[] achr = {stm_type};
    return new String(achr);
    }

 /**
  *  Method for get value from aVector of process string 
  *  if not defined return for display blank Strine
  *
  */	
 public Object  get(int idx){
   if (idx == 0 ){           // Case TimeStamp field
     return new Long(value);
   }else if ( row.size() < idx){
	 return  "";
	}else{
     return row.get(--idx);
	}
  }
  
  public int size(){
     return this.row.size() + 1;   
   }


 /**
  * Method for set value
  *
  *
  */
  
  public void set (int idx,Object obj) { 
     row.add(idx,obj); 
   }

  public void set (Object obj) {
    row.add(obj);
   }
 
 /**
  *   setOUT(str) - set to array  according current  proc_no  
  */

 public void  setOUT(Object obj){
   row.add(proc_no,obj);
  }

 /**
  setOUT(int proc_no,String str) set to array  according to proc_no

 */

 public void  setOUT(int proc_no,Object obj){
   row.add(proc_no,obj);
   this.proc_no = proc_no ;
  }  

  

 public void value(int  v)
  {
   this.value = (long)v;
  }

 public void value(long v)
  {
   this.value = v;
  }
 
 public void value(double v)
  {
   this.value = (long)v;
  }
 
 public long value()
  {
   return this.value;
  }

    /**
     * Returns the value of this <code>Long</code> as a
     * <code>byte</code>.
     */
    public byte byteValue() {
	return (byte)value;
    }

    /**
     * Returns the value of this <code>Long</code> as a
     * <code>short</code>.
     */
    public short shortValue() {
	return (short)value;
    }

    /**
     * Returns the value of this <code>Long</code> as an
     * <code>int</code>.
     */
    public int intValue() {
	return (int)value;
    }

    /**
     * Returns the value of this <code>Long</code> as a
     * <code>long</code> value.
     */
    public long longValue() {
	return (long)value;
    }

    /**
     * Returns the value of this <code>Long</code> as a
     * <code>float</code>.
     */
    public float floatValue() {
	return (float)value;
    }

    /**
     * Returns the value of this <code>Long</code> as a
     * <code>double</code>.
     */
    public double doubleValue() {
	return (double)value;
    }

    /**
     * Returns a <code>String</code> object representing this
     * <code>Long</code>'s value.  The value is converted to signed
     * decimal representation and returned as a string, exactly as if
     * the <code>long</code> value were given as an argument to the
     * {@link java.lang.Long#toString(long)} method.
     *
     * @return  a string representation of the value of this object in
     *		base&nbsp;10.
     */
    public String toString() {
	return String.valueOf(value);
    }
  
 
  
}

