/******** Demo4: Automatic plan forcing **********/
/* Making sure Automatic plan forcing is turned ON */
ALTER DATABASE CURRENT

SET AUTOMATIC_TUNING(FORCE_LAST_GOOD_PLAN = ON);
GO

/* Checking the tuning options if the option is enabled */
SELECT *
FROM sys.database_automatic_tuning_options

/* Creating the Stored procedure */
IF EXISTS (
		SELECT *
		FROM sys.objects
		WHERE type = 'P'
			AND name = 'Salesinformation'
		)
	DROP PROCEDURE dbo.Salesinformation
GO

CREATE PROCEDURE dbo.Salesinformation @productID [int]
AS
BEGIN
	SELECT [SalesOrderID]
		,[ProductID]
		,[OrderQty]
	FROM [Sales].[SalesOrderDetailEnlarged]
	WHERE [ProductID] = @productID;
END;

/* Clearing the Query store */
ALTER DATABASE [AdventureWorks]

SET QUERY_STORE CLEAR;

/* Clean the procedure cache */
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE

/* Creating the first workload */
EXEC dbo.Salesinformation 942 GO 50

/* Clean the procedure cache */
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE

/* Creating Regression */
EXEC dbo.Salesinformation 707 GO 10

/* Run the workload again */
EXEC dbo.Salesinformation 942 GO 30

/* Check for the Automatic plan correction in the Query Store */
/* Check for the tuning recommendations */
SELECT *
FROM sys.dm_db_tuning_recommendations