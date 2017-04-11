#region Functions
#Convert our PSCustom object to a datatable that our SQL Merge can understand
function ConvertTo-DataTable {
    <#
    .EXAMPLE
    $DataTable = ConvertTo-DataTable $Source
    .PARAMETER Source
    An array that needs converted to a DataTable object
    #>
    [CmdLetBinding(DefaultParameterSetName="None")]
    param(
        [Parameter(Position=0,Mandatory=$true)][System.Array]$Source,
        [Parameter(Position=1,ParameterSetName='Like')][String]$Match=".+",
        [Parameter(Position=2,ParameterSetName='NotLike')][String]$NotMatch=".+"
    )
    if ($NotMatch -eq ".+"){
        $Columns = $Source[0] | Select * | Get-Member -MemberType NoteProperty | Where-Object {$_.Name -match "($Match)"}
    } else {
    $Columns = $Source[0] | Select * | Get-Member -MemberType NoteProperty | Where-Object {$_.Name -notmatch "($NotMatch)"}
    }
    $DataTable = New-Object System.Data.DataTable
    foreach ($Column in $Columns.Name)
    {
        $DataTable.Columns.Add("$($Column)") | Out-Null
    }
    #For each row (entry) in source, build row and add to DataTable.
    foreach ($Entry in $Source) {
        $Row = $DataTable.NewRow()
        foreach ($Column in $Columns.Name)
        {
            $Row["$($Column)"] = if($Entry.$Column -ne $null){($Entry | Select-Object -ExpandProperty $Column) -join ', '}else{$null}
        }
        $DataTable.Rows.Add($Row)
    }

    #Validate source column and row count to DataTable
    if ($Columns.Count -ne $DataTable.Columns.Count){
        throw "Conversion failed: Number of columns in source does not match data table number of columns"
    } else{ 
        if($Source.Count -ne $DataTable.Rows.Count){
            throw "Conversion failed: Source row count not equal to data table row count"
        } else{
        #The use of "Return ," ensures the output from function is of the same data type; otherwise it's returned as an array.
        Return ,$DataTable
        }
    }
}
#endregion

#Merge the datatable into SQL
Set-Location C:\temp\meta
$ServerInstance = 'sqldb.com'
$Database = 'mysqldb'
$Target = 'dbo.Domain_Members'
$Source = ConvertTo-DataTable -Source (Import-Csv .\domain_members.csv)
$MergeTable = 'Domain_Members'
$UniqueIdentifier = 'Domain_VPN'

if (!(Test-Connection 127.0.0.1 -Count 1)) {
    Write-Warning "Not connected to the VPN"
    break
}

#Create connection object to SQL instance
$SQLConnection = New-Object System.Data.SqlClient.SqlConnection
$SQLConnection.ConnectionString = "Server = $ServerInstance;Database=$Database;User ID=$($cred.UserName);Password=$($cred.GetNetworkCredential().password);"
$SQLConnection.Open()

#Get columns for table in SQL and compare to column in source DataTable
$SQLCommand = New-Object System.Data.SqlClient.SqlCommand
$SQLCommand.Connection = $SQLConnection
$SQLCommand.CommandText = "SELECT $($Filter) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_Name = '$(($Target.Split(".") | Select -Index 1))'"
$SQLAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
$SQLAdapter.SelectCommand = $SQLCommand
$SQLColumns = New-Object System.Data.DataTable
$SQLAdapter.Fill($SQLColumns) | Out-Null
$Columns = $SQLColumns.COLUMN_NAME

#What is the primary key of the target table
$PrimaryKey = New-Object System.Data.DataTable
$SQLCommand.CommandText = "SELECT * FROM INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE WHERE TABLE_Name = '$($Target.Split(".") | Select -Index 1)' AND CONSTRAINT_NAME LIKE 'PK_%'"
$SQLAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
$SQLAdapter.SelectCommand = $SQLCommand
$SQLAdapter.Fill($PrimaryKey) | Out-Null
$PrimaryKey = $PrimaryKey | Where-Object {$_.CONSTRAINT_NAME -like 'PK_*'} | Select -ExpandProperty COLUMN_NAME -First 1


#Create temporary table for bulk insert
$CreateColumns = ($CreateColumns = foreach($Column in ($Columns | Where-Object {$_ -ne $PrimaryKey})){"["+$Column+"] [nvarchar] (max) NULL"}) -join ","
$SQLQuery = "CREATE TABLE $($Target)_$($UniqueIdentifier)_TEMP([$($PrimaryKey)] [nvarchar](255) NOT NULL PRIMARY KEY, $CreateColumns)"
$SQLCommand.CommandText = $SQLQuery
$Results = $SQLCommand.ExecuteNonQuery()


#Bulk insert source DataTable into temporary SQL table
$SQLBulkCopy = New-Object ("System.Data.SqlClient.SqlBulkCopy") $SQLConnection
$SQLBulkCopy.DestinationTableName = "$($Target)_$($UniqueIdentifier)_TEMP"
$SQLBulkCopy.BatchSize = 5000
$SQLBulkCopy.BulkCopyTimeout = 0
foreach ($Column in $Columns){[void]$SQLBulkCopy.ColumnMappings.Add($Column, $Column)}
Try {
    $SQLBulkCopy.WriteToServer($Source)
} Catch {
    Write-Warning 'A Hell NOOOOOOOOO! Error occured NUKE EM FROM ORBIT!'
    exit
}


#Build and execute SQL merge command
#$Updates = (($Updates = foreach ($Column in $Columns -ne $PrimaryKey)
#{
#    "Target.[$($Column)]"+" = "+("Source.[$($Column)]")
#}) -join ",")
$InsertColumns = ($InsertColumns = foreach ($Column in $Columns){"[$Column]"}) -join ","
$InsertValues = ($InsertValues = foreach ($Column in $Columns){"Source.[$Column]"}) -join ","

#Find out the conditions we need and what table we will be merging on
Write-Verbose "We will be merging on $MergeTable, so we will run a switch statement to find out what conditions to apply"
switch ($MergeTable) {
    "AD_Group_Membership" {
        $MergeCondition = "AND Target.GroupName = '$Group' AND Target.Domain = '$Domain'"
        $UpdateCondition = $null
    }
    "AD_Groups" {
        $MergeCondition = "AND Target.Domain = '$Domain'"
        $UpdateCondition = "Target.whenchanged = Source.whenchanged"
    }
    "Domain_Members" {
        $MergeCondition = "AND Target.Domain = '$Domain'"
        $UpdateCondition = "Target.email = Source.email, Target.employeeid = Source.employeeid, Target.employeenumber = Source.employeenumber"
    }
    "Domain_Members_Attributes" {
        $MergeCondition = "AND Target.AttributeName = '$($AttributeSyncJob)_$Attribute'"
        $UpdateCondition = "Target.AttributeValue = Source.AttributeValue"
        $UpdateConditionWhenMatched = "and Target.AttributeValue != Source.AttributeValue"
    }
}

#I am so sorry about this block of code, it is highly dynamic and well it works. It avoided me duplicating it multiple times
#Do not align this text, as it will cause it to break!
$SQLQuery = @"
MERGE INTO $($Target) WITH (READPAST) AS Target
USING $($Target)_$($UniqueIdentifier)_TEMP AS Source
ON Target.[$($PrimaryKey)] = Source.[$($PrimaryKey)]
WHEN NOT MATCHED THEN
INSERT ($InsertColumns) VALUES ($InsertValues)
$(#If condition to see if we actually need a Update Condition
if ($UpdateCondition -notlike $null) {
"WHEN MATCHED $(if ($UpdateConditionWhenMatched) {$UpdateConditionWhenMatched})
THEN UPDATE SET $UpdateCondition"})
WHEN NOT MATCHED BY Source $MergeCondition THEN
DELETE;
"@

#How this really looks broken down, see why I hate myself now?
"
    MERGE INTO $($Target) WITH (READPAST) AS Target
    USING $($Target)_$($UniqueIdentifier)_TEMP AS Source
    ON Target.[$($PrimaryKey)] = Source.[$($PrimaryKey)]
    WHEN NOT MATCHED THEN
        INSERT ($InsertColumns) VALUES ($InsertValues)
    $(#If condition to see if we actually need a Update Condition
        if ($UpdateCondition -notlike $null) {
            "WHEN MATCHED $(
                if ($UpdateConditionWhenMatched) {
                    $UpdateConditionWhenMatched
                }
            )
                THEN UPDATE SET $UpdateCondition"
        }
    )
    WHEN NOT MATCHED BY Source $MergeCondition THEN
        DELETE;
"
#########################################################################################################################################################
#Merge Outputs
#########################################################################################################################################################
#Native Merge Query
<#
MERGE INTO  WITH (READPAST) AS Target
USING __TEMP AS Source
ON Target.[] = Source.[]
WHEN NOT MATCHED THEN
INSERT () VALUES ()

WHEN NOT MATCHED BY Source  THEN
DELETE;
#>

#No Switch Statement
<#
MERGE INTO dbo.Domain_Members WITH (READPAST) AS Target
USING dbo.Domain_Members_DOMAIN_Test_TEMP AS Source
ON Target.[domsam] = Source.[domsam]
WHEN NOT MATCHED THEN
INSERT ([domsam],[samaccountname],[Domain],[Email],[employeenumber],[OktaID],[employeeid]) VALUES (Source.[domsam],Source.[samaccountname],Source.[Domain],Source.[Email],Source.[employeenumber],Source.[OktaID],Source.[employeeid])

WHEN NOT MATCHED BY Source  THEN
DELETE;
#>

#Domain_Members_Loaded
<#
MERGE INTO dbo.Domain_Members WITH (READPAST) AS Target
USING dbo.Domain_Members_DOMAIN_Test_TEMP AS Source
ON Target.[domsam] = Source.[domsam]
WHEN NOT MATCHED THEN
INSERT ([domsam],[samaccountname],[Domain],[Email],[employeenumber],[OktaID],[employeeid]) VALUES (Source.[domsam],Source.[samaccountname],Source.[Domain],Source.[Email],Source.[employeenumber],Source.[OktaID],Source.[employeeid])
WHEN MATCHED 
THEN UPDATE SET Target.email = Source.email, Target.employeeid = Source.employeeid, Target.employeenumber = Source.employeenumber
WHEN NOT MATCHED BY Source AND Target.Domain = 'LAN' THEN
DELETE;
#>