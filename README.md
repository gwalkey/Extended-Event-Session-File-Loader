# Extended-Event-Session-Loader
This Powershell example takes an Extended Events .XEL file as input and loads the Session trace data into a SQL Table for further processing

Background:
The SQL Server built-in Function '''sys.fn_xe_file_target_read_file''' is INCREDIBLY SLOW.

This project utilizes two SQL Server DLLs that are present on every installation of SQL Server:
* Microsoft.SqlServer.XE.Core.dll
* Microsoft.SqlServer.XEvent.Linq.dll

There are two versions of this project:
1) A File Reader - this repo
2) A Stream Reader - found here

I Typically run the XEL File Reader to load Successful or Failed Logins into a SQL Table Fronted by a Power BI Dashboard to see where my Bad logins are coming from

I Typically run the Stream reader with an XE session that watches for Deadlocks, but you can watch any XE Session
Feel free to extend and embrace the code to trigger alerts, send email 
