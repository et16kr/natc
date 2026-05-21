import java.util.Properties;
import java.sql.*;

class sample 
{
	public static void main(String args[]) 
	{
		String url;
		AtcLib atc= new AtcLib();
		
		atc.SetUrl("20535");
		atc.CreateConnection();
        atc.CreateConnection();
        atc.CreateStatement();		

		try 
		{
			atc.atcStmt.execute("drop table test");
		}
		catch (SQLException e)
		{
			System.err.println(e);
		}
		
		try {
			atc.atcStmt.execute("create table test (name varchar(20) )");
			System.out.println("Create Table Test Success");
		}
		catch (SQLException e)
		{
			System.err.println(e);
		}
	}
}
