# Extended-Event-Session-File-Loader
This Powershell example takes an Extended Events .XEL file as input and loads the Session trace data into a SQL Table for further processing

<h2>Background</h2>
The SQL Server built-in XE File read function <b>sys.fn_xe_file_target_read_file</b> is INCREDIBLY SLOW.

I needed a faster method to load large XEL trace files into a SQL table.

Turns out Microsoft already has one, they just dont talk about it much

Performance difference between using the built-in function and the DLL Libraries
![alt text](https://raw.githubusercontent.com/gwalkey/SSAS_DW_Logins/master/Import_Library_Comparison.jpg)

<h2>Shout-Out and Props</h2> 
https://blogs.msdn.microsoft.com/extended_events/2011/07/20/introducing-the-extended-events-reader/
https://dba.stackexchange.com/questions/206863/what-is-the-right-tool-to-process-big-xel-files-sql-server-extended-events-log?rq=1
https://itsalljustelectrons.blogspot.com/2017/01/SQL-Server-Extended-Event-Handling-Via-Powershell.html

  
<h2>Requirements</h2>
* Windows Powershell 5.1 or Powershell 7
* .Net Framework 4.8 or .Net Core 3.X runtimes
* Microsoft.SqlServer.XE.Core.dll
* Microsoft.SqlServer.XEvent.Linq.dll

<h2>Editions</h2>
There are two Editions of this project:
1) A File Reader - this repo
2) A Stream Reader - found here

<h2>Usage</h2>
I typically run the XEL File Reader to load Failed Logins into a SQL Table fronted by a Power BI Dashboard to see where my Bad logins are coming from
I typically run the Stream Reader against an XE session that tracks Deadlocks, but you can watch any XE Session

Feel free to extend and embrace the code to trigger alerts, send emails, call an API etc
