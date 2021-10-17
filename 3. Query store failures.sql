/* Demo 3: Query store failures */
/* Force the plan for dbo.StockInfo stored procedure from WideWorldImportersDW database created from the 2nd demo */
/* 
	 DROP INDEX [OderQuantity] ON [Fact].[Order]
	GO
*/
/*clear the Query store */
ALTER DATABASE WideWorldImportersDW

SET QUERY_STORE CLEAR;

/* Clean the procedure cache */
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE

/* Creating the supporting index */
USE [WideWorldImportersDW]
GO

CREATE NONCLUSTERED INDEX OderQuantity ON [Fact].[Order] ([Quantity]) INCLUDE (
	[Order Key]
	,[Stock Item Key]
	)
GO

/* Rerun the stored procedure */
USE WideWorldImportersDW
GO

EXEC dbo.StockInfo 360;

/* force the plan */
/* Dropping, altering the objects used in the forced plan can cause failures */
/* Drop the index */
USE [WideWorldImportersDW]
GO

DROP INDEX OderQuantity ON [Fact].[Order]

/* Rerun the sp */
USE WideWorldImportersDW
GO

EXEC dbo.StockInfo 360;

/* Check for the failures in Query store (Queries with Forced Plans) */
/*create the index again */
USE [WideWorldImportersDW]
GO

CREATE NONCLUSTERED INDEX OderQuantity ON [Fact].[Order] ([Quantity]) INCLUDE (
	[Order Key]
	,[Stock Item Key]
	)
GO

/* Rerun the sp */
USE WideWorldImportersDW
GO

EXEC dbo.StockInfo 360;

/* Changing the key columns in index */
USE [WideWorldImportersDW]
GO

CREATE INDEX OderQuantity ON [Fact].[Order] (
	[Quantity]
	,[Order Key]
	)
	WITH (DROP_EXISTING = ON);

/* Rerun the sp */
USE WideWorldImportersDW
GO

EXEC dbo.StockInfo 360;
GO

/* Check for the failures in Query store (Queries with Forced Plans) or 
use the catalog views to monitor failures */