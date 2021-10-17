/* Demo2: Database upgrade scenario, behavior at different compatability levels */
/* restoring the database WideWorldImportersDW from 
https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImportersDW-Full.bak
*/
/* restore database WideWorldImportersDW
from
disk='C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\Backup\WideWorldImportersDW-Full.bak'
with move
'WWI_Primary' to 'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\WideWorldImportersDW.mdf',
move 'WWI_UserData' to 'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\WideWorldImportersDW.ndf',
move 'WWI_Log' to 'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\WideWorldImportersDW_log.ldf',
move 'WWIDW_InMemory_Data_1' to 'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\WWIDW_InMemory_Data_1'

restore filelistonly from disk=
'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\Backup\WideWorldImportersDW-Full.bak'
*/
/* free the cache */
DBCC FREEPROCCACHE

/* enable the Query store on the database */
ALTER DATABASE WideWorldImportersDW

SET QUERY_STORE = ON (OPERATION_MODE = READ_WRITE);

/* set query store options 
Source code: https://docs.microsoft.com/en-us/sql/relational-databases/performance/monitoring-performance-by-using-the-query-store?view=sql-server-ver15
*/
ALTER DATABASE WideWorldImportersDW

SET QUERY_STORE(OPERATION_MODE = READ_WRITE, CLEANUP_POLICY = (STALE_QUERY_THRESHOLD_DAYS = 30), DATA_FLUSH_INTERVAL_SECONDS = 3000, MAX_STORAGE_SIZE_MB = 500, INTERVAL_LENGTH_MINUTES = 15, SIZE_BASED_CLEANUP_MODE = AUTO, QUERY_CAPTURE_MODE = AUTO, MAX_PLANS_PER_QUERY = 1000, WAIT_STATS_CAPTURE_MODE = ON);

/* change the compatability of database to 110 */
USE Master
GO

ALTER DATABASE WideWorldImportersDW

SET COMPATIBILITY_LEVEL = 110;

/*  
Query from the Microsoft docs 
https://docs.microsoft.com/en-us/sql/relational-databases/performance/joins?view=sql-server-ver15#adaptive
Placed the Query to run as a stored procedure
*/
USE WideWorldImportersDW
GO

IF EXISTS (
		SELECT *
		FROM sys.objects
		WHERE type = 'P'
			AND name = 'StockInfo'
		)
	DROP PROCEDURE dbo.StockInfo
GO

CREATE PROCEDURE dbo.StockInfo @Quantity [int]
AS
BEGIN
	SELECT [fo].[Order Key]
		,[si].[Lead Time Days]
		,[fo].[Quantity]
	FROM [Fact].[Order] AS [fo]
	INNER JOIN [Dimension].[Stock Item] AS [si] ON [fo].[Stock Item Key] = [si].[Stock Item Key]
	WHERE [fo].[Quantity] = @Quantity;
END;

/*clear the Query store */
ALTER DATABASE WideWorldImportersDW

SET QUERY_STORE CLEAR;

/*clear the cache */
DBCC FREEPROCCACHE

/*Execute the stored procedure */
USE WideWorldImportersDW
GO

EXEC dbo.StockInfo 360;

/* change the compatability level of the database to 130 */
USE Master
GO

ALTER DATABASE WideWorldImportersDW

SET COMPATIBILITY_LEVEL = 130;

/* rerun the stored procedure */
USE WideWorldImportersDW
GO

EXEC dbo.StockInfo 360;