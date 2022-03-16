# Extended-Event-Session-Loader
This Powershell example takes an XEL filename as input and loads the SQL Server Extended Events Session trace data into a SQL Table for processing

Background:
The SQL Server built-in Function '''sys.fn_xe_file_target_read_file''' is INCREDIBLY SLOW.

This project utilizes two SQL Server DLLs that are present on every installation of SQL Server:
* Microsoft.SqlServer.XE.Core.dll
* Microsoft.SqlServer.XEvent.Linq.dll

There are two versions of this project:
1) A File Reader
2) A Stream Reader

I Typically run the Stream reader with an XE session that watches for Deadlocks, but you can watch any XE Session
Feel free to extend and embrace the code to trigger alerts, send email 
