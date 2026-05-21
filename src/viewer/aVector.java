 

import java.util.Vector;

/* aVector autoextanded by add and constructor class  */

class aVector extends Vector
 {


 aVector (){
    super();
  }

 aVector (int it){
   super(it);
   this.setSize(it);
  }
 
 aVector (int iC, int cI){
   super(iC,cI);
   setSize(iC);
  }

 aVector (Object[] value){ 
   elementCount =  value.length;
   elementData  =  value;
  }


 public synchronized void add (int idx, Object obj)
  {
    if (size() < idx + 1 ) 
	{
	  setSize(idx + 1);
	}
    set(idx,obj);
  }//add


} // aVactor

