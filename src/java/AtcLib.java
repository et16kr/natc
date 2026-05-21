import java.util.Properties;
import java.sql.*;

/**********************$*******************************************************
	ATC LIB
******************************************************************************/
class AtcLib
{
	Properties props = new Properties();
	String url;
	String portno;
	String user;
	String password;
	String encoding;

	Connection atcCn 			= null;
	Statement atcStmt 			= null;
	PreparedStatement atcPStmt 	= null;
	ResultSet atcRs 			= null;
	ResultSetMetaData atcMeta	= null;

	public AtcLib()
	{
		String user 	= "SYS";
		String password = "MANAGER";
		String encoding = "US7ASCII";

		SetUser(user);
		SetPassword(password);
		SetEncoding(encoding);

		CreateDriverManager();
	}

/**************************************
	Set Properties
**************************************/
	public void SetUser(String user)
	{
		props.put("user", user);
	}

	public void SetPassword(String password)
	{
		props.put("password", password);
	}
	
	public void SetEncoding(String encoding)
	{
		props.put("encoding", encoding);
	}

/**************************************
	SetUrl
**************************************/
	public String SetUrl(String portno)
	{
		return url = "jdbc:Altibase://127.0.0.1:" + portno + "/mydb";
	}

	public String SetUrl(String portno, String dataSource)
	{
		return url = "jdbc:Altibase://" + dataSource + ":" + portno + "/mydb";
	}

	public String SetUrl(String portno, String dataSource, String dbName)
	{
		return url = "jdbc:Altibase://" + dataSource + ":" + portno + "/" + dbName;
	}

/**************************************
	Create DriverManager
**************************************/
	public void CreateDriverManager ()
	{
        try 
		{
			Class.forName("Altibase.jdbc.driver.AltibaseDriver");
        } 
		catch (Exception e) 
		{
            System.err.println("Cannot Driver Load");
            System.err.println(e);
			return;
        }		
	}
	
/**************************************
	Create Connection
**************************************/
    public void CreateConnection()
	{
		atcCn = null;
		try 
		{
			atcCn = java.sql.DriverManager.getConnection(this.url, this.props);
		}
		catch (Exception e)
		{
            e.printStackTrace();
			return;
		}
    }

/**************************************
	Create Statement
**************************************/
    public void CreateStatement()
	{
		try 
		{
			atcStmt = atcCn.createStatement();
		}
		catch (Exception e)
		{
            e.printStackTrace();
			return;
		}
    }

/**************************************
	Create ResultSet
**************************************/
	public void CreateResultSet(String stmt)
	{
		try
		{
			atcRs = atcStmt.executeQuery(stmt);
		}
		catch (SQLException e)
		{
			
		}
	}

/**************************************
	Create PreparedStatement 
**************************************/
	public void CreatePrepareStatement(String str)
	{
		try 
		{
			atcPStmt = atcCn.prepareStatement(str);
		}	
		catch (SQLException e)
		{
			
		}
	}

/**************************************
	Create ResultSetMetaData
**************************************/
	public void CreateResultSetMetaData(String str)
	{
		try
		{
			atcRs = atcStmt.executeQuery(str);
		}
		catch (Exception e)
		{
			System.err.println(e);	
			return;
		}
	}

/**************************************
	ResultSet Next
**************************************/

/**************************************
	GetString
**************************************/

/**************************************
	Atc 
**************************************/
	public void AtcSector(String sectionNumber,  String sectionTitle)
	{
		System.out.println("+----------------------------------------------------------");
		
		System.out.println("--+SECTOR " +  sectionNumber + "; " + sectionTitle);
		System.out.println("+----------------------------------------------------------");
	}

	public void AtcSuccess()
	{
		System.out.println("SUCCESS");
	}

	public void AtcFailure()
	{
		System.out.println("FAILURE");
	}

/**************************************
	SQLCA 
**************************************/
	public void SQLCA(SQLWarning w)
	{
		System.err.print("MSG :");
		System.err.println(w.getMessage());
		System.err.print("SQLSTATE :");
		System.err.println(w.getSQLState());
		System.err.print("ERRRORCODE :");
		System.err.println(w.getErrorCode());
	}

/**************************************
	Close ResultSet
**************************************/
	public void CloseResultSet()
	{
		try
		{
			atcRs.close();
			atcRs = null;
		}
		catch(SQLException e)
		{
			System.err.println(e);
			return;
		}
	}

/**************************************
	Close Connection
**************************************/
	public void CloseConnection()
	{
		try
		{
			atcCn.close();
			atcCn = null;
		}
		catch(SQLException e)
		{
			System.err.println(e);
			return;
		}
	}
}
