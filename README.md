# Extended-Event-Session-File-Loader
This Powershell example takes an Extended Events .XEL file as input and loads the Session trace data into a SQL Table for further processing

# Background
The SQL Server built-in XE File read function <b>sys.fn_xe_file_target_read_file</b> is INCREDIBLY SLOW.

I needed a faster method to load large XEL trace files into a SQL table.

Turns out Microsoft already has one, they just dont talk about it much

# ETL Performance
* Using sys.fn_xe_file_target_read_file = 11 Hours
* Using XEvent.Linq.dll and XECore.dll assemblies - 11 Minutes

![alt text](https://raw.githubusercontent.com/gwalkey/SSAS_DW_Logins/master/Import_Library_Comparison.jpg)

# Shout-Outs and Props
https://blogs.msdn.microsoft.com/extended_events/2011/07/20/introducing-the-extended-events-reader/
https://dba.stackexchange.com/questions/206863/what-is-the-right-tool-to-process-big-xel-files-sql-server-extended-events-log?rq=1
https://itsalljustelectrons.blogspot.com/2017/01/SQL-Server-Extended-Event-Handling-Via-Powershell.html

  
# Requirements
* Windows Powershell 5.1 or Powershell 7
* .Net Framework 4.8 or .Net Core 3.X runtimes
* Microsoft.SqlServer.XE.Core.dll
* Microsoft.SqlServer.XEvent.Linq.dll

# Editions
There are two Editions of this project:
1) A File Reader - this repo
2) A Stream Reader - found here

# Usage
I typically run the XEL File Reader to load Failed Logins into a SQL Table fronted by a Power BI Dashboard to see where my Bad logins are coming from<br>
I typically run the Stream Reader against an XE session that tracks Deadlocks, but you can watch any XE Session

Sample:
powershell.exe c:\psscripts\XEvents_File_Reader.ps1 -Server 'localhost' -XELFilePath 'c:\traces\XE_Filed_Logins*.xel'

-Server is the destination SQL Server you will be pushing the XE events into<br>
-Database is the Database<br>
-Table is the table you will load the events into<br>

# Code Customization required
As every Extended Event Session you create is different, with varying data elements captured, you will be creating a SQL Table to hold those same elements.

Accordingly, we must 
1) Create a SQL Server load table with a schema to accomodate our XE Session event attributes
2) Create a Powershell Datatable in the ps1 script whose schema matches our SQL Load table
3) Add each parsed XE Event to the Posh datatable so that we can use the SQL Bulk Copy API to quickly load the events into SQL in batches (configurable)

# Setup
Full Setup instructions are in the Wiki<br>
https://github.com/gwalkey/Extended-Event-Session-File-Loader/wiki/Setup-Instructions

Feel free to extend and embrace the code to trigger alerts, send emails, call an API etc
