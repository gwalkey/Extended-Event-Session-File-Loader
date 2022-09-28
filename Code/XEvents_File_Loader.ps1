<#
.SYNOPSIS
	Parses Extended Event Session XEL Trace Files into a 
    SQL Table using SQL Server Library DLLs 
    and the [QueryableXEventData] Namespace
	
.DESCRIPTION
    Parses Extended Event Session XEL Trace Files into a 
    SQL Table using SQL Server Library DLLs 
    and the [QueryableXEventData] Namespace
	
.EXAMPLE
 	
.EXAMPLE
 
.EXAMPLE
 
.Inputs
   
.Outputs

.NOTES
   
.LINK
    https://github.com/gwalkey/Extended-Event-Session-File-Loader

#>

#
[CmdletBinding()]
Param(
    [parameter(Position=0,mandatory=$true,ValueFromPipeline)]
    [ValidateNotNullOrEmpty()]
    [string]$Server='localhost',
    [parameter(Position=1,mandatory=$true,ValueFromPipeline)]
    [ValidateNotNullOrEmpty()]
    [string]$Database='FailedLogins',
    [parameter(Position=2,mandatory=$true,ValueFromPipeline)]
    [ValidateNotNullOrEmpty()]
    [string]$Table='XE_Trace_Load',
    [parameter(Position=3,mandatory=$true,ValueFromPipeline)]
    [string]$XELFilePath='c:\traces\XE_Failed_Logins*.xel'
)

Set-StrictMode -Version latest;
Clear-Host
   
# Load Assemblies with Hard-Coded filepath
# 130=2016
# 140=2017
# 150=2019
# 160=2022
$SQLVersion=150

[int]$BulkCopyBatchSize = 1000

try
{
    Add-Type -Path "C:\Program Files\Microsoft SQL Server\$SQLVersion\Shared\Microsoft.SqlServer.XE.Core.dll"
}
catch
{
    $PoshError = $PSItem.tostring()
    throw('Cant Load DLL: {0}' -f $PoshError)
}

try
{
    Add-Type -Path "C:\Program Files\Microsoft SQL Server\$SQLVersion\Shared\Microsoft.SqlServer.XEvent.Linq.dll"
}
catch
{
    $PoshError = $PSItem.tostring()
    throw('Cant Load DLL: {0}' -f $PoshError)
}

Write-Output('Importing XEL Files from [{0}]' -f $XELFilePath)

# Create Datatable for SqlBulkCopy
$DT   = New-Object System.Data.DataTable
$col1 = New-object system.Data.DataColumn timestamp,([datetime])
$col2 = New-object system.Data.DataColumn server_instance_name,([string])
$col3 = New-object system.Data.DataColumn error_number,([string])
$col4 = New-object system.Data.DataColumn client_hostname,([string])
$col5 = New-object system.Data.DataColumn client_app_name,([string])
$col6 = New-object system.Data.DataColumn database_name,([string])
$col7 = New-object system.Data.DataColumn username,([string])
$col8 = New-object system.Data.DataColumn severity,([int])
$col9 = New-object system.Data.DataColumn message,([string])

$DT.columns.add($col1)
$DT.columns.add($col2)
$DT.columns.add($col3)
$DT.columns.add($col4)
$DT.columns.add($col5)
$DT.columns.add($col6)
$DT.columns.add($col7)
$DT.columns.add($col8)
$DT.columns.add($col9)


# Open and Read XEL files using DLL Namespace
try
{
    $Events = New-Object Microsoft.SqlServer.XEvent.Linq.QueryableXEventData($XELFilePath) -ErrorAction Stop
}
catch
{
    $PoshError = $PSItem.tostring()
    Throw('Cant Open the XE source files, Error[{0}]' -f $PoshError)
}

# Truncate the Load Table
$SQLConnectionString         = "Data Source=$Server;Initial Catalog=$Database;Integrated Security=SSPI;"
$Connection                  = New-Object System.Data.SqlClient.SqlConnection
$SqlCmd                      = New-Object System.Data.SqlClient.SqlCommand
$Connection.ConnectionString = $SQLConnectionString
$Connection.Open()
$SqlCmd.Connection           = $Connection
$SqlCmd.CommandText          = "truncate table $Table"

# Execute statement
try
{
    $ExecResponse = $SqlCmd.ExecuteNonQuery()
}
catch
{
    $Connection.Close()
    $SQLError = $PSItem.tostring()
    Throw('Error Truncating SQL Table [{0}]' -f $SQLError)
}

$Connection.Close()


# How many events do we have?
Write-Output('Event Count: [{0}]' -f @($Events).count)

# Setup BulkCopy Object
$bcp = New-Object System.Data.SqlClient.SqlBulkCopy("Data Source=$Server;Initial Catalog=$Database;Integrated Security=SSPI",[System.Data.SqlClient.SqlBulkCopyOptions]::TableLock)
$bcp.DestinationTableName = $Table

# Init event Counter
[int]$EventCount=0

# Process all Events
foreach($event in $Events)
{
    # Count rows in DT/BulkCopy batch
    $EventCount+=1

    # Add new Datatable Row
    $Row = $DT.NewRow()

    # Parse out the XE trace columns we are interested in loading to SQL from each Event
    $Row["timestamp"]            = $event.Timestamp.LocalDateTime
    $UpperServer                 = $event.Actions["server_instance_name"].Value
    $UpperServer                 = $UpperServer.toupper()
    $Row["server_instance_name"] = $UpperServer
    $error_number                = [string]$event.Fields["error_number"].Value
    $Row["error_number"]         = $error_number

    # If username Actions object is missing, keep going
    $ErrorActionPreference       = "SilentlyContinue"

    $Row["client_app_name"]      = [string]$event.Actions["client_app_name"].Value
    $Row["database_name"]        = [string]$event.Actions["database_name"].Value    
    $Row["severity"]             = [int]$event.Fields["severity"].Value
    $message                     = [string]$event.Fields["message"].Value
    $Row["message"]              = $message


    # Special Processing for certain Error Numbers - 17806 - derive client IP from Message
    if ($error_number -eq '17806')
    {
        if ($message.IndexOf("[CLIENT: ") -ge 0)
        {

            $i1 = $message
            [int]$i2 = $i1.indexof("[CLIENT: ")
            $i2=$i2+9
            [int]$i3 = $i1.indexof("]",$i2)
            $i4 = $i1.Substring($i2,$i3-$i2)            
            $ParsedClientName = $i4            
            
            $Row["client_hostname"] = $ParsedClientName
        }
        else
        {
            $Row["client_hostname"]  = [string]$event.Actions["client_hostname"].Value
        }
    }
    else
    {
        $Row["client_hostname"]  = [string]$event.Actions["client_hostname"].Value
    }

    # Special Processing for Username
    $session_nt_username         = [string]$event.Actions["session_nt_username"].Value
    $nt_username                 = [string]$event.Actions["nt_username"].Value
    $username                    = [string]$event.Actions["username"].Value
    
    $ParsedUsername = $null
    if ($session_nt_username -ne $null -and $session_nt_username -ne '')
    {
       $ParsedUsername 
    }
    if ($nt_username -ne $null -and $nt_username -ne '')
    {
       $ParsedUsername 
    }
    if ($username -ne $null -and $username -ne '')
    {
       $ParsedUsername 
    }

    # If Username is still null, parse the Message field, looking for something like
    # "Login failed for user 'nn'. Reason: Could not find a login matching the name provided. [CLIENT: 10.0.245.99]"
    if ($null -eq $ParsedUsername)
    {
        if ($message.IndexOf("Login failed for user") -ge 0)
        {
            $i1 = $message
            $i2 = $i1 -replace "Login failed for user '",""
            $i3 = $i2.indexof("'.")
            $i4 = $i2.Substring(0,$i3)
            $ParsedUsername = $i4
        }

    }
    $Row["username"]             =  $ParsedUsername

    # Add our Row to the Datatable
    $DT.Rows.Add($Row)
    $ErrorActionPreference = "Continue"

    # Batch Bulk Copy 
    if($eventCount % $BulkCopyBatchSize -eq 0)
    {
        $bcp.WriteToServer($DT)
        $DT.Rows.Clear()
        Write-output("SQL BulkCopy {0:N0} Events" -f $EventCount)
    }

}

# Write last batch
Write-output("SQL BulkCopy Wrote [{0:N0}] Total Events" -f $EventCount)
$bcp.WriteToServer($dt) 
$bcp.Close()

# Clean up
$Events.dispose()
$Events = $null

