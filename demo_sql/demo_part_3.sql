-- DEMO part 3 KS
USE TRG_DB

--1. czyszczenie œrodowiska, je¿eli potrzebne

		DECLARE @KeyName NVARCHAR(256);
		DECLARE key_cursor CURSOR FOR 
		SELECT name FROM sys.symmetric_keys WHERE name NOT LIKE '##MS_DatabaseMasterKey##';
 
		OPEN key_cursor;
		FETCH NEXT FROM key_cursor INTO @KeyName;
 
		WHILE @@FETCH_STATUS = 0
		BEGIN
			DECLARE @sql NVARCHAR(MAX) = 'DROP SYMMETRIC KEY [' + @KeyName + ']';
			PRINT 'Usuwam klucz: ' + @KeyName;
			EXEC sp_executesql @sql;
 
			FETCH NEXT FROM key_cursor INTO @KeyName;
		END
 
		CLOSE key_cursor;
		DEALLOCATE key_cursor;

		GO

		DECLARE @sql NVARCHAR(MAX) = '';
 
		-- Tworzenie dynamicznego zapytania do usuniêcia tabel
		SELECT @sql += 'DROP TABLE [' + TABLE_SCHEMA + '].[' + TABLE_NAME + '];' + CHAR(13)
		FROM INFORMATION_SCHEMA.TABLES
		WHERE TABLE_SCHEMA = 'dbo' AND TABLE_TYPE = 'BASE TABLE';
 
		-- Wykonanie zapytania
		PRINT @sql; -- Podgl¹d przed wykonaniem
		EXEC sp_executesql @sql;

		-- Usuwam stored procedures
		DECLARE @procName NVARCHAR(256);
		DECLARE cur CURSOR FOR
			SELECT name
			FROM sys.objects
			WHERE type = 'P' AND is_ms_shipped = 0

		OPEN cur
		FETCH NEXT FROM cur INTO @procName

		WHILE @@FETCH_STATUS = 0
		BEGIN
			PRINT('DROP PROCEDURE ' + @procName)
			EXEC('DROP PROCEDURE ' + @procName)
			FETCH NEXT FROM cur INTO @procName
		END

		CLOSE cur
		DEALLOCATE cur

--2. export danych --> python  

--3. connection do TRG DB

USE TRG_DB

SELECT *  FROM [dbo].[Customer]

-- lista kluczy symetrycznych na bazie danych 
 SELECT * FROM sys.symmetric_keys

-- utworzenie klucza
CREATE SYMMETRIC KEY [Recreatable_Symmetric_Key] 
	WITH
		ALGORITHM = AES_256,
		KEY_SOURCE = 'Secret_Key_Source_value',
		IDENTITY_VALUE = 'MyIdentity'
	ENCRYPTION BY PASSWORD = 'StrongPassword123!'

-- lista kluczy symetrycznych na bazie danych po utworzeniu klucza symetrycznego
 SELECT * FROM sys.symmetric_keys


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

 
-- wnioski
