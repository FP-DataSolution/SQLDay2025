-- DEMO part 4 KP
USE TRG_DB

--odszyfrowanie danych

OPEN SYMMETRIC KEY [Recreatable_Symmetric_Key]  
DECRYPTION BY PASSWORD = 'StrongPassword123!'

SELECT
	[CustomerID],
	[NameStyle],
	[Title],
	CAST(DECRYPTBYKEY([FirstName_encrypted]) AS NVARCHAR(4000)) AS [FirstName],
	CAST(DECRYPTBYKEY([MiddleName_encrypted]) AS NVARCHAR(4000)) AS [MiddleName],
	CAST(DECRYPTBYKEY([LastName_encrypted]) AS NVARCHAR(4000)) AS [LastName],
	[Suffix],
	[CompanyName],
	[SalesPerson],
	CAST(DECRYPTBYKEY([EmailAddress_encrypted]) AS NVARCHAR(4000)) AS [EmailAddress],
	CAST(DECRYPTBYKEY([Phone_encrypted]) AS NVARCHAR(4000)) AS [Phone],
	[rowguid],
	[ModifiedDate]
FROM [dbo].[Customer]

CLOSE SYMMETRIC KEY [Recreatable_Symmetric_Key]


-- z�y password

OPEN SYMMETRIC KEY [Recreatable_Symmetric_Key]  
DECRYPTION BY PASSWORD = 'WrongPassword'

SELECT
	[CustomerID],
	[NameStyle],
	[Title],
	CAST(DECRYPTBYKEY([FirstName_encrypted]) AS NVARCHAR(4000)) AS [FirstName],
	CAST(DECRYPTBYKEY([MiddleName_encrypted]) AS NVARCHAR(4000)) AS [MiddleName],
	CAST(DECRYPTBYKEY([LastName_encrypted]) AS NVARCHAR(4000)) AS [LastName],
	[Suffix],
	[CompanyName],
	[SalesPerson],
	CAST(DECRYPTBYKEY([EmailAddress_encrypted]) AS NVARCHAR(4000)) AS [EmailAddress],
	CAST(DECRYPTBYKEY([Phone_encrypted]) AS NVARCHAR(4000)) AS [Phone],
	[rowguid],
	[ModifiedDate]
FROM [dbo].[Customer]


-- z�a nazwa klucza
OPEN SYMMETRIC KEY [WrongKey]  
DECRYPTION BY PASSWORD = 'StrongPassword123!'

SELECT
	[CustomerID],
	[NameStyle],
	[Title],
	CAST(DECRYPTBYKEY([FirstName_encrypted]) AS NVARCHAR(4000)) AS [FirstName],
	CAST(DECRYPTBYKEY([MiddleName_encrypted]) AS NVARCHAR(4000)) AS [MiddleName],
	CAST(DECRYPTBYKEY([LastName_encrypted]) AS NVARCHAR(4000)) AS [LastName],
	[Suffix],
	[CompanyName],
	[SalesPerson],
	CAST(DECRYPTBYKEY([EmailAddress_encrypted]) AS NVARCHAR(4000)) AS [EmailAddress],
	CAST(DECRYPTBYKEY([Phone_encrypted]) AS NVARCHAR(4000)) AS [Phone],
	[rowguid],
	[ModifiedDate]
FROM [dbo].[Customer]

-- brak klucza

SELECT
	[CustomerID],
	[NameStyle],
	[Title],
	CAST(DECRYPTBYKEY([FirstName_encrypted]) AS NVARCHAR(4000)) AS [FirstName],
	CAST(DECRYPTBYKEY([MiddleName_encrypted]) AS NVARCHAR(4000)) AS [MiddleName],
	CAST(DECRYPTBYKEY([LastName_encrypted]) AS NVARCHAR(4000)) AS [LastName],
	[Suffix],
	[CompanyName],
	[SalesPerson],
	CAST(DECRYPTBYKEY([EmailAddress_encrypted]) AS NVARCHAR(4000)) AS [EmailAddress],
	CAST(DECRYPTBYKEY([Phone_encrypted]) AS NVARCHAR(4000)) AS [Phone],
	[rowguid],
	[ModifiedDate]
FROM [dbo].[Customer]


--- utworzenie widok�w zawieraj�cych decrypt


SET NOCOUNT ON

DECLARE @TableName NVARCHAR(128)
DECLARE @SchemaName NVARCHAR(128)
DECLARE @SqlQuery NVARCHAR(MAX)
DECLARE @int INT
DECLARE @no_of_tables INT
DECLARE @counter INT = 0
DECLARE @objects AS TABLE (
	rn INT,
	schema_name VARCHAR(MAX),
	table_name VARCHAR(MAX)
	)

INSERT INTO @objects
SELECT ROW_NUMBER() OVER (ORDER BY s.schema_id)  as RN,
	s.name AS schema_name, t.name as table_name
FROM sys.schemas s
	INNER JOIN sys.tables t
	ON s.schema_id = t.schema_id
WHERE s.name IN ('dbo')

SET @int = (SELECT COUNT(*)
FROM @objects)
SET @no_of_tables = @int

WHILE @int > 0
BEGIN
	SET @TableName = (SELECT TOP 1
		table_name
	FROM @objects
	ORDER BY RN);
	SET @SchemaName = (SELECT TOP 1
		schema_name
	FROM @objects
	ORDER BY RN);
	SET @SqlQuery = '
	CREATE OR ALTER VIEW ['+ @SchemaName +'].[VW_'+ @TableName +'] AS
	SELECT';
	SELECT @SqlQuery = @SqlQuery +
		CASE
			WHEN COLUMN_NAME LIKE '%_encrypted' THEN
				' CAST(DECRYPTBYKEY(['+ COLUMN_NAME +']) AS NVARCHAR(4000)) AS ['+ COLUMN_NAME + '],'
			ELSE
				' [' + COLUMN_NAME + '],'
		END
	FROM INFORMATION_SCHEMA.COLUMNS
	WHERE TABLE_NAME = @TableName
		AND TABLE_SCHEMA = @SchemaName

	SET @SqlQuery = LEFT(@SqlQuery, LEN(@SqlQuery) - 1) + ' FROM [' +@SchemaName + '].['+ @TableName +']';

	DELETE FROM @objects WHERE table_name = @TableName AND schema_name = @SchemaName

	BEGIN TRY
		PRINT (@SqlQuery)
		 EXEC (@SqlQuery)
		SET @counter = @counter + 1
	END TRY
	BEGIN CATCH
		PRINT('View not created')
	END CATCH

	SET @SqlQuery = ''
	SET @int = (SELECT COUNT(*)
	FROM @objects)
END

SELECT CAST(@counter AS VARCHAR)+'/'+CAST(@no_of_tables AS VARCHAR)+' views created.' AS INFO




-- podgl�d utworzonowego widoku

SELECT [CustomerID]
      , [NameStyle]
      , [Title]
      , [Suffix]
      , [CompanyName]
      , [SalesPerson]
      , [rowguid]
      , [ModifiedDate]
      , [FirstName_encrypted]
      , [MiddleName_encrypted]
      , [LastName_encrypted]
      , [EmailAddress_encrypted]
      , [Phone_encrypted]
FROM [dbo].[VW_Customer]

-- otworzenie klucza symetrycznego (klucz trzymany jest w sesji)

OPEN SYMMETRIC KEY [Recreatable_Symmetric_Key] 
DECRYPTION BY PASSWORD = 'StrongPassword123!'

-- 
SELECT [CustomerID]
      , [NameStyle]
      , [Title]
      , [Suffix]
      , [CompanyName]
      , [SalesPerson]
      , [rowguid]
      , [ModifiedDate]
      , [FirstName_encrypted]
      , [MiddleName_encrypted]
      , [LastName_encrypted]
      , [EmailAddress_encrypted]
      , [Phone_encrypted]
FROM [dbo].[VW_Customer]


CLOSE SYMMETRIC KEY [Recreatable_Symmetric_Key]

-- pr�by odszyfrowania danych nie zapisuj� si� w historii zapyta�

SELECT deqs.last_execution_time AS [Time], dest.text AS [Query]
FROM sys.dm_exec_query_stats AS deqs
CROSS APPLY sys.dm_exec_sql_text(deqs.sql_handle) AS dest
ORDER BY 1 desc


select *
FROM [dbo].[Customer]

SELECT
	CAST(DECRYPTBYKEY([FirstName_encrypted]) AS NVARCHAR(4000)) AS [FirstName]
FROM [dbo].[Customer]

OPEN SYMMETRIC KEY [Recreatable_Symmetric_Key] 
DECRYPTION BY PASSWORD = 'StrongPassword123!'

CLOSE SYMMETRIC KEY [Recreatable_Symmetric_Key] ;

-- procedura z has�em

CREATE OR ALTER PROCEDURE USP_OPEN_SYMM_KEY
WITH
	ENCRYPTION,
	EXECUTE AS OWNER
AS
BEGIN
	OPEN SYMMETRIC KEY [Recreatable_Symmetric_Key] 
	DECRYPTION BY PASSWORD = 'StrongPassword123!'
END

CREATE OR ALTER PROCEDURE USP_CLOSE_SYMM_KEY
WITH
	ENCRYPTION,
	EXECUTE AS OWNER
AS
BEGIN
	CLOSE SYMMETRIC KEY [Recreatable_Symmetric_Key]
END


-- przyk�ad:
SELECT *
FROM [dbo].[VW_Customer]

EXEC USP_OPEN_SYMM_KEY
SELECT *
FROM [dbo].[VW_Customer]

EXEC USP_CLOSE_SYMM_KEY
SELECT *
FROM [dbo].[VW_Customer]

-- definicja procedury nie jest jawna
SELECT DISTINCT
	o.name AS Object_Name,
	o.type_desc,
	m.*
FROM sys.sql_modules m
	INNER JOIN sys.objects o ON m.object_id = o.object_id

-- wnioski