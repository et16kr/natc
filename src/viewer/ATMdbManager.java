import java.io.*;
import java.sql.*;
import java.text.*;


public class  ATMdbManager{
  
  protected           String       dbDriver = "Altibase.jdbc.driver.AltibaseDriver";
 //protected           String       dbDriver = "org.postgresql.Driver";
  protected           String          dbusr = "sys";
  protected           String          dbpwd = "manager";
  protected           String          dbenc = "US7ASCII";
  protected           String          dburl = "jdbc:Altibase://192.168.1.3:20550/mydb";
                   Statement            stm = null;  // Statment
            DatabaseMetaData           dbmd = null;  // This defines the structure of the database 
                  Connection             db = null;  // The connection to the database



  public ATMdbManager () throws ClassNotFoundException,
                                FileNotFoundException, 
                                IOException,
                                SQLException
  {// begin ATMdbManager
   Class.forName(System.getProperty("atc.JDBC_DRIVER"    ,dbDriver));
   this.dburl  = System.getProperty("atc.CONF_DB_URL"    ,   dburl);
   this.dbusr  = System.getProperty("atc.CONF_DB_USER"   ,   dbusr);
   this.dbpwd  = System.getProperty("atc.CONF_DB_PASSWD" ,   dbpwd);
   

   // Connect to database
   //  System.out.println("Connecting to Database URL = " + dburl);
   
   this.db = DriverManager.getConnection(dburl,dbusr, dbpwd);
   this.stm = db.createStatement();                       // Create Statment          

  dbmd = db.getMetaData();                           // Get MetaData
  // This prints the backend's version
     System.out.println("Connected to "
                        + dbmd.getDatabaseProductName() + " "
                        + dbmd.getDatabaseProductVersion());
  
  }//end ATMdbManager
   
  public int getVersion() throws SQLException {
    ResultSet
  	 res  =  stm.executeQuery("SELECT MAX(VERSION) FROM TEST_VERSION");
	 if(res.next()){
	   int ret =  res.getInt(1);
	   res.close();
       return ret;
	 }else{	 
       return -1; 
	}  
 }
  /**  Function for get Lits by sql query from Altibase Test atabse
   *   
   *
   *
   */

  
  public aVector getListBySQL(int index,String SQL) throws SQLException{
   aVector ret = new aVector();
    ResultSet
      res = stm.executeQuery(SQL);
      while (res.next()){
	     if (res.wasNull()){ 
           ret.add("null");
		  }else{
           ret.add(res.getObject(index));
         }
	   }	
	  res.close();	
    return ret;
  }// getTestSuteList



 public aVector     getTestSuteList() throws SQLException{
   return getListBySQL(1,"SELECT TS_NAME  FROM TEST_SUITE");
  }
 
 public aVector getTestCaseList()  throws SQLException{
    return getListBySQL(1,"SELECT TC_NAME FROM TEST_CASE"); 
 }//getTestCaseList

 


 /**
  * This displays a result set.
  * Note: it closes the result once complete.
  */
    public void displayResult(ResultSet rs) throws SQLException
    {
        ResultSetMetaData rsmd = rs.getMetaData();

        // Print the result column names
        int cols = rsmd.getColumnCount();
        for (int i = 1;i <= cols;i++)
            System.out.print(rsmd.getColumnLabel(i) + (i < cols ? "\t" : "\n"));

        // now the results
        while (rs.next())
        {
            for (int i = 1;i <= cols;i++)
            {
                Object o = rs.getObject(i);
                if (rs.wasNull())
                    System.out.print("{null}" + (i < cols ? "\t" : "\n"));
                else
                    System.out.print(o.toString() + (i < cols ? "\t" : "\n"));
            }
        }

        // finally close the result set
	  rs.close();
    }

 /**
  *  Dis displays a result set.  
  */
  public void displayResult( aVector v){
   for (int i = 0; i < v.size(); i++){
     System.out.println(v.get(i));
    }
   	
  } 
 
 
  public static void main(String[] args) {

    if (args.length > 0 ) System.setProperty("atc.CONF_DB_URL"   ,args[0]); 
    if (args.length > 1 ) System.setProperty("atc.CONF_DB_USER"  ,args[1]);       
    if (args.length > 2 ) System.setProperty("atc.CONF_DB_PASSWD",args[2]);
    if (args.length > 3 ) System.setProperty("atc.JDBC_DRIVER",args[3]);
   try{ ATMdbManager 
    atm  = new ATMdbManager();
    atm.displayResult( atm.getTestSuteList() );
    atm.displayResult( atm.getTestCaseList() ); 
    System.out.println("Tast Cases Version  " + atm.getVersion());
   }catch (Exception e){
	 e.printStackTrace();
   } 
  } 

}
