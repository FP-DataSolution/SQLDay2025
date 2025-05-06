-- DEMO part 5 KP
USE TRG_DB

SELECT  *
  FROM [dbo].[Customer]


-- lista kluczy symetrycznych na bazie danych
 SELECT * FROM sys.symmetric_keys


-- utworzenie kolejnego odtwarzalnego klucza symetrycznego potrzebnego do zaszyfrowania danych

 CREATE SYMMETRIC KEY [Additional_Symmetric_Key] 
	WITH
		KEY_SOURCE = 'Another_Key_Source_value',
		ALGORITHM = AES_256,
		IDENTITY_VALUE = 'SecondIdentity'
	ENCRYPTION BY PASSWORD = 'TopSecretPassword123!'

-- lista kluczy symetrycznych na bazie danych
 SELECT * FROM sys.symmetric_keys

 ----
 SELECT  *
  FROM [dbo].[Customer]


  --modyfikacja tabeli
  ALTER TABLE [dbo].[Customer]
  ADD [CustomerID_encrypted] varbinary(4000),
	  [NameStyle_encrypted] varbinary(4000),
	  [Title_encrypted] varbinary(4000),
	  [Suffix_encrypted] varbinary(4000),
	  [CompanyName_encrypted] varbinary(4000),
	  [SalesPerson_encrypted] varbinary(4000),
	  [rowguid_encrypted] varbinary(4000),
	  [ModifiedDate_encrypted] varbinary(4000)
	  
--- TYPY DANYCH na wejœciu == TYPY DANYCH na wyjœciu --- rozszerzyæ myœl

OPEN SYMMETRIC KEY [Additional_Symmetric_Key]
DECRYPTION BY PASSWORD = 'TopSecretPassword123!'

UPDATE [dbo].[Customer]
SET [CustomerID_encrypted] = ENCRYPTBYKEY(KEY_GUID('Additional_Symmetric_Key'), CONVERT(varbinary(4000), CAST([CustomerID] AS NVARCHAR(4000)))),
	[NameStyle_encrypted] = ENCRYPTBYKEY(KEY_GUID('Additional_Symmetric_Key'), CONVERT(varbinary(4000), CAST([NameStyle] AS NVARCHAR(4000)))),
	[Title_encrypted] = ENCRYPTBYKEY(KEY_GUID('Additional_Symmetric_Key'),CONVERT(varbinary(4000), CAST([Title] AS NVARCHAR(4000)))),
	[Suffix_encrypted] = ENCRYPTBYKEY(KEY_GUID('Additional_Symmetric_Key'),CONVERT(varbinary(4000), CAST([Suffix] AS NVARCHAR(4000)))),
	[CompanyName_encrypted] = ENCRYPTBYKEY(KEY_GUID('Additional_Symmetric_Key'), CONVERT(varbinary(4000), CAST([CompanyName] AS NVARCHAR(4000)))),
	[SalesPerson_encrypted] = ENCRYPTBYKEY(KEY_GUID('Additional_Symmetric_Key'), CONVERT(varbinary(4000), CAST([SalesPerson] AS NVARCHAR(4000)))),
	[rowguid_encrypted] = ENCRYPTBYKEY(KEY_GUID('Additional_Symmetric_Key'), CONVERT(varbinary(4000), CAST([rowguid] AS NVARCHAR(4000)))),
	[ModifiedDate_encrypted] = ENCRYPTBYKEY(KEY_GUID('Additional_Symmetric_Key'), CONVERT(varbinary(4000), CAST([ModifiedDate] AS NVARCHAR(4000))))


-- sprawdzenie zaszyfrowanych danych
CLOSE SYMMETRIC KEY Recreatable_Symmetric_Key
CLOSE SYMMETRIC KEY Additional_Symmetric_Key
SELECT  *
  FROM [dbo].[Customer]

-- usuniêcie niezaszyfrowanych danych
ALTER TABLE [dbo].[Customer]
DROP COLUMN [CustomerID], [NameStyle], [Title], [Suffix], [CompanyName], [SalesPerson], [rowguid], [ModifiedDate]

SELECT  *
  FROM [dbo].[Customer]



  --- utworzenie widoków zawieraj¹cych decrypt


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
			WHEN COLUMN_NAME LIKE '%_encrypted%' THEN
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


--- wejœcie do widoku

OPEN SYMMETRIC KEY Additional_Symmetric_Key
DECRYPTION BY PASSWORD = 'TopSecretPassword123!'

OPEN SYMMETRIC KEY Recreatable_Symmetric_Key
DECRYPTION BY PASSWORD = 'StrongPassword123!'


SELECT * FROM [dbo].[VW_Customer]


--- wejœcie do widoku
CLOSE SYMMETRIC KEY Additional_Symmetric_Key
CLOSE SYMMETRIC KEY Recreatable_Symmetric_Key

SELECT * FROM [dbo].[VW_Customer]

-- wnioski

-- bonus: procesowanie w pythonie 
