/******** Demo1: How to Force and unforce plans ********/
/* We are using Adventureworks database for this Demo
Enlarged the AdventureWorks Sample Database by using the Jonathan Kehayias Script
Source: https://www.sqlskills.com/blogs/jonathan/enlarging-the-adventureworks-sample-databases/
Two tables gets created: 
[Sales].[SalesOrderHeaderEnlarged]
[Sales].[SalesOrderDetailEnlarged]
*/
/*Enable Query store on database throught T-sql */
ALTER DATABASE [AdventureWorks]

SET QUERY_STORE = ON (OPERATION_MODE = READ_WRITE);

/* set query store options 
Source code: https://docs.microsoft.com/en-us/sql/relational-databases/performance/monitoring-performance-by-using-the-query-store?view=sql-server-ver15
*/
ALTER DATABASE [AdventureWorks]

SET QUERY_STORE(OPERATION_MODE = READ_WRITE, CLEANUP_POLICY = (STALE_QUERY_THRESHOLD_DAYS = 30), DATA_FLUSH_INTERVAL_SECONDS = 3000, MAX_STORAGE_SIZE_MB = 500, INTERVAL_LENGTH_MINUTES = 15, SIZE_BASED_CLEANUP_MODE = AUTO, QUERY_CAPTURE_MODE = AUTO, MAX_PLANS_PER_QUERY = 1000, WAIT_STATS_CAPTURE_MODE = ON);

/*clear the Query store */
ALTER DATABASE [AdventureWorks]

SET QUERY_STORE CLEAR;

/* Clean the procedure cache */
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE

/* what are my current Query store options? */
SELECT actual_state_desc
	,desired_state_desc
	,current_storage_size_mb
	,max_storage_size_mb
	,readonly_reason
	,interval_length_minutes
	,stale_query_threshold_days
	,size_based_cleanup_mode_desc
	,query_capture_mode_desc
FROM sys.database_query_store_options;

/* run some queries to collect the data into Query store */
USE [AdventureWorks]

EXEC [Sales].[customerdata_OrderDate] '2011-01-31'
	,'2012-01-31'

USE [AdventureWorks]

EXEC [Sales].[SalesHeaderData] 279

/*Check the Query store using GUI to see the Query plans for above queries */
/* Check the procedure plans in the plan cache
Source: https://www.sqlshack.com/understanding-sql-server-query-plan-cache/
*/
SELECT cplan.usecounts
	,cplan.objtype
	,qtext.TEXT
	,qplan.query_plan
FROM sys.dm_exec_cached_plans AS cplan
CROSS APPLY sys.dm_exec_sql_text(plan_handle) AS qtext
CROSS APPLY sys.dm_exec_query_plan(plan_handle) AS qplan
ORDER BY cplan.usecounts DESC

/* Clean the procedure cache */
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE

/*will this clear out Query store plans as well? 
Source: https://docs.microsoft.com/en-us/sql/relational-databases/performance/monitoring-performance-by-using-the-query-store?view=sql-server-ver15*/
SELECT Txt.query_text_id
	,Txt.query_sql_text
	,Pl.plan_id
	,Qry.*
FROM sys.query_store_plan AS Pl
INNER JOIN sys.query_store_query AS Qry ON Pl.query_id = Qry.query_id
INNER JOIN sys.query_store_query_text AS Txt ON Qry.query_text_id = Txt.query_text_id;

/*clear the Query store */
ALTER DATABASE [AdventureWorks]

SET QUERY_STORE CLEAR;

/* lets see some adhoc query examples */
SELECT [SalesOrderID]
	,[ProductID]
	,[OrderQty]
FROM [Sales].[SalesOrderDetailEnlarged]
WHERE [ProductID] = 836 GO 2

SELECT [SalesOrderID]
	,[ProductID]
	,[OrderQty]
FROM [Sales].[SalesOrderDetailEnlarged]
WHERE [ProductID] = 835 GO 2

/*
SELECT [ProductID], COUNT(ProductID)
FROM [Sales].[SalesOrderDetailEnlarged]
GROUP BY [ProductID]
HAVING COUNT(ProductID)>1
order by COUNT(ProductID) desc
*/
/*slightly change the code or add a space- creates a new plan with new query id*/
SELECT [SalesOrderID]
	,[ProductID]
	,[OrderQty]
FROM [Sales].[SalesOrderDetailEnlarged]
WHERE [ProductID] = 835

/*wrapping the same code in a stored procedure to avoid multiple plans */
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
	WHERE [ProductID] = @productID
	OPTION (RECOMPILE);
END;

/*clear the Query store */
ALTER DATABASE [AdventureWorks]

SET QUERY_STORE CLEAR;

/* Clean the procedure cache */
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE

/* execute the stored procedure using different parameters*/
EXEC dbo.Salesinformation 942

EXEC dbo.Salesinformation 707

/* force the optimal plan and test the execution */
EXEC sp_query_store_force_plan @query_id = 1
	,@plan_id = 1;

EXEC dbo.Salesinformation 900

/* Unforce the forced plan and execute the sp again */
--Exec dbo.Salesinformation 942
--Exec dbo.Salesinformation 707
/* Turning the Query store to read only mode */
ALTER DATABASE [AdventureWorks]

SET QUERY_STORE = ON (OPERATION_MODE = READ_ONLY);

/* Clean the procedure cache */
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE

/* rerun the sp and see if the forced plan is still used */
EXEC dbo.Salesinformation 707

/* Turning off the query store */
ALTER DATABASE [AdventureWorks]

SET QUERY_STORE = OFF