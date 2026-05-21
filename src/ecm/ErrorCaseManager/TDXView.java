import java.io.*;
import java.util.*;
import java.awt.*;
import java.awt.event.*;
import javax.swing.*;
import javax.swing.table.*;
import javax.swing.JTextArea.*;

class ReadFile
{
    public int max_time = 0;
    public int max_process = 0;

    // 전체 라인 수(마지막 추가로 넣어준 START 마크 빼주기 위해서)
    public int total_line_cnt = -1;

    public Vector tableData = new Vector();
    public Vector temp = new Vector();
    public String fileName;

    public ReadFile( String fn )
    {
        this.fileName = fn;
    }

    void readFile()
    {
        String strToken;
        StringTokenizer stok;
        StringTokenizer stok2;
        BufferedReader bufReader1 = null;
        BufferedReader bufReader2 = null;

        String statement;
        StringBuffer strBuf = null;
        strBuf = new StringBuffer();

        File file = new File( fileName );

        int add_row = 0;
        int cur_line = 0;
        int cur_process = 0;
        int cur_time = 0;
        int i = 0;

        try
        {
            bufReader1 = new BufferedReader( new FileReader( file ) );
            bufReader2 = new BufferedReader( new FileReader( file ) );
        }
        catch( Exception e )
        {
            System.err.println(e);
        }

        if ( !file.canRead() )
        {
            System.err.println( "Error: I can't read file" );
            System.exit(1);
        }

        // max_process를 구하기 위한 loop
        // max_time을 구하기 위한 loop
        while( true )
        {
            // get line
            try
            {
                // String Tokenizer
                try
                {
                    // readLine() 후 다시 이 지점으로 돌아오기 위해 marking
                    // 최소한 한 라인의 글자수만큼 되야 한다.
                    bufReader1.mark( 300 );
                }
                catch( IOException e )
                {
                    System.err.println( e.toString() );
                }

                if (bufReader1.readLine().startsWith("&^<@!START!@>"))
                {
                    try
                    {
                        bufReader1.reset();
                    }
                    catch( IOException e )
                    {
                        System.err.println( e.toString() );
                    }
                    
                    stok = new StringTokenizer(bufReader1.readLine(), "&^");

                    for (i = 0; stok.hasMoreTokens(); i++)
                    {
                        strToken = stok.nextToken();

                        // parseInt 시, try, catch 해줘야 함
                        switch ( i )
                        {
                            case 2:
                            {
                                this.max_time++;

                                try
                                {
                                    cur_process = Integer.parseInt(strToken.substring(1));
                                }
                                catch( Exception ex )
                                {
                                    System.err.println( ex.toString() );
                                    System.err.println( "Time Parsing error");
                                }

                                if (cur_process > this.max_process )
                                {
                                    this.max_process = cur_process;
                                }
                                break;
                            }
                            default:
                            {
                                break;
                            }
                        }
                    }
                }
                else
                {
                    try
                    {
                        bufReader1.reset();
                    }
                    catch( IOException e )
                    {
                        System.err.println( e.toString() );
                    }
                    bufReader1.readLine();
                }
            }
            catch (Exception e)
            {
              // Stop readLine if null EOF same == null
                break;
            }
            // total_lint_cnt 증가
            this.total_line_cnt++;
        }
        try
        {
            bufReader1.close();
        }
        catch (IOException e)
        {
            System.err.println( e.toString() );
        }

        // System.out.println( "!!! " + this.max_process );
        // System.out.println( "!!! " + this.max_time );
        // System.out.println( "!!! " + this.total_line_cnt );
        // System.exit(1);

        // 우선 tableData안의 모든 Element를 초기화해줘야 한다.
        for ( i = 0; i < ( this.total_line_cnt ) * ( this.max_process + 2 ); i++ )
        {
            tableData.add( "" );
        }

        // 총 컬럼의 개수
        add_row = this.max_process + 2;

        // vector에 데이터 값을 집어넣는 loop
        // 여기서 만든 vector를 가지고, TableModel을 만든다.
        while( true )
        {
            // get line
            try
            {
                // readLine() 후 다시 이 지점으로 돌아오기 위해 marking
                // 최소한 한 라인의 글자수만큼 되야 한다.
                bufReader2.mark( 300 );

                // start mark가 있고, strBuf에 내용이 들어있으면 tableData에 입력한다.
                if ( bufReader2.readLine().startsWith( "&^<@!START!@>") )
                {
                    bufReader2.reset();

                    if ( strBuf.toString().length() != 0 )
                    {
                        // START바로 전에 읽은 것을 쓴다.
                        tableData.setElementAt( String.valueOf( cur_time ), cur_line - add_row );
                        tableData.setElementAt( bufReader2.readLine(), cur_line - add_row + cur_process + 1 );

                        // strBuf 초기화
                        strBuf.delete( 0, strBuf.capacity() );
                        strBuf.setLength( 0 );
                    }

                    stok = new StringTokenizer( bufReader2.readLine(), "&^");

                    for ( i = 0; stok.hasMoreTokens(); i++ )
                    {
                        strToken =  stok.nextToken();

                        // parseInt 시, try, catch 해줘야 함
                        switch ( i )
                        {
                            case 0:
                            {
                                if ( strToken.equals( "&^<@!START!@>" ) )
                                {
                                    // System.out.println( "START Mark OK!!" );
                                }
                                break;
                            }
                            case 1:
                            {
                                try
                                {
                                    cur_time = Integer.parseInt( strToken );

                                    // 시간은 항상 컬럼0 에 찍힌다.
                                    tableData.setElementAt( String.valueOf( cur_time ), cur_line );
                                }
                                catch ( Exception ex )
                                {
                                    System.err.println( ex.toString() );
                                    System.err.println( "Time Parsing error");
                                }
                                break;
                            }
                            case 2:
                            {
                                try
                                {
                                    cur_process = Integer.parseInt( strToken.substring(1, 2) );
                                }
                                catch( Exception e )
                                {
                                    System.err.println( "Process Number Parsing error");
                                }
                                break;
                            }
                            // 실제 내용( readLine의 마지막 부분 )
                            case 3:
                            {
                                // cur_time, cur_process, max_process를 이용하여 각 원소가
                                // table의 어디에 입력할지 결정한다.
                                tableData.setElementAt( strToken, cur_line + cur_process + 1 );
                                break;
                            }
                            default :
                            {
                                break;
                            }
                        }
                    } // for loop
                } // line with start mark?
                else
                {
                    bufReader2.reset();

                    tableData.setElementAt( String.valueOf( cur_time ), cur_line );

                    stok2 = new StringTokenizer( bufReader2.readLine(), "&^" );

                    tableData.setElementAt( stok2.nextToken(), cur_line + cur_process + 1 );
                }
            }
            catch (Exception e)
            {
                // Stop readLine if null EOF same == null
                break;
            }
            cur_line += add_row;
        } // while loop
        try
        {
            bufReader2.close();
        }
        catch ( IOException e )
        {
        }
    }

    // Time으로 오름차순 정렬한다.
    void tableSort()
    {
        int i, j, k;
        int cell_value1 = 0;
        int cell_value2 = 0;

        // 총 컬럼의 개수
        int add_row = this.max_process + 2;

        // 우선 tableData안의 모든 Element를 초기화해줘야 한다.
        // temp는 컬럼의 수만큼의 element를 갖는다.
        for ( i = 0; i < add_row; i++ )
        {
            temp.add( "" );
        }

        for (i = 0; i < total_line_cnt - 1; i++)
        {
            for (j = total_line_cnt - 1; j > i; j--)
            {
                cell_value1 = Integer.parseInt( (String) tableData.elementAt( j * add_row) );
                cell_value2 = Integer.parseInt( (String) tableData.elementAt( (j - 1) * add_row) );

                // System.out.println( cell_value1 );
                // System.out.println( cell_value2 );

                if ( cell_value2 > cell_value1 )
                {
                    // Vector temp에 한줄의 원소를 넣기 위한 loop
                    for( k = 0; k < add_row; k++ )
                    {
                        temp.setElementAt( tableData.elementAt((j - 1) * add_row + k), k );
                    }
                    for( k = 0; k < add_row; k++ )
                    {
                        tableData.setElementAt( tableData.elementAt(j * add_row + k), (j - 1) * add_row + k );
                    }
                    for( k = 0; k < add_row; k++ )
                    {
                        tableData.setElementAt( temp.elementAt(k), j * add_row + k );
                    }
                }
            }
        }
    }
}

class MakeTable extends AbstractTableModel
{
    private int max_row; // time
    private int max_column; // time column + process column
    Vector tableData;

    MakeTable( int max_time, int max_process, Vector td )
    {
        this.max_row = max_time;

        // process가 0부터 시작하기 때문에 1 더하고,
        // 맨 처음 column은 time이므로 1 더한다.
        this.max_column = max_process + 2;
        this.tableData = td;
    }

    public int getRowCount()
    {
        return this.max_row;
    }

    public int getColumnCount()
    {
        return this.max_column;
    }

    public Object getValueAt( int row, int column )
    {
         // System.out.println( tableData.elementAt( row * this.max_column + column ).toString() );
        return tableData.elementAt( row * this.max_column + column );
    }

    public String getColumnName(int column)
    {
        if ( column == 0 )
        {
            return "Time";
        }
        else
        {
            return "Process P" + ( column - 1 );
        }
    }

    public String getRowName( int row )
    {
        return "Time " + row;
    }

    void makeTable()
    {
        for( int i = 0; i < max_row; i++ )
        {
            for( int j = 0; j < max_column; j++ )
            {
                getValueAt( i, j );
            }
        }
    }
}

class GUIView extends JFrame
{
    BorderLayout borderLayout1 = new BorderLayout();
    JScrollPane jScrollPane1 = new JScrollPane();

    JTable jt;

    public GUIView( MakeTable mt, String fileName )
    {
        super( "TDX Viewer" + ": " + fileName );

        jt = new JTable(mt);

        try
        {
            jbInit();
        }
        catch(Exception ex)
        {
            ex.printStackTrace();
        }
    }

    void jbInit() throws Exception
    {
        try
        {
            UIManager.setLookAndFeel(UIManager.getSystemLookAndFeelClassName());
        }
        catch (Exception e)
        {
        }

        this.setBounds(10,10,860,480);
        this.getContentPane().setLayout(borderLayout1);

        jt.getColumnModel().getColumn(0).setMaxWidth(70);

        //jt.getColumnModel().setColumnSelectionAllowed(true);

        //jt.setMaximumSize(new Dimension(32767, 32767));
        //jt.setMinimumSize(new Dimension(800, 600));
        //jt.setPreferredSize(new Dimension(800, 600));

        jScrollPane1.setMaximumSize(new Dimension(32767, 32767));
        jScrollPane1.setMinimumSize(new Dimension(800, 600));
        jScrollPane1.setPreferredSize(new Dimension(800, 600));

        this.getContentPane().add(jScrollPane1, BorderLayout.CENTER);

        jScrollPane1.add(jt);
        jScrollPane1.getViewport().add(jt, null);
        // setSize(860, 640);
        setVisible(true);
    }
}

class TDXView
{
    public static void main( String args[] )
    {
        if (args.length == 0 )
        {
            System.err.println("[ERROR]: should be parametr!");
            System.err.println("[Usage]: tdxview xxxx.tdx");
            System.exit(1);
        }

        ReadFile rf = new ReadFile( args[0] );
        rf.readFile();

        // 첫번째 컬럼인 Time으로 오름차순 정렬한다.
        rf.tableSort();

        MakeTable mt = new MakeTable( rf.total_line_cnt, rf.max_process, rf.tableData );
        mt.makeTable();

        GUIView test = new GUIView(mt, args[0]);
        test.setVisible(true);

        test.addWindowListener( new WindowAdapter() 
        {
            public void windowClosing(WindowEvent e) 
            {
                System.exit(1);
            }
        } );
    }
}

