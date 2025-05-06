-- DEMO part 2 KS
-- SRC_DB

USE SRC_DB

--db_init

-- inicjalna wersja tabeli z danymi

SELECT  *
  FROM [dbo].[Customer]


-- lista kluczy symetrycznych na bazie danych
 SELECT * FROM sys.symmetric_keys


 -- utworzenie odtwarzalnego klucza symetrycznego potrzebnego do zaszyfrowania danych, uwaga na sk³adniê
 -- 

 CREATE SYMMETRIC KEY [Recreatable_Symmetric_Key] 
	WITH
		KEY_SOURCE = 'Secret_Key_Source_value',
		ALGORITHM = AES_256,
		IDENTITY_VALUE = 'MyIdentity'
	ENCRYPTION BY PASSWORD = 'StrongPassword123!'
	
-- lista kluczy symetrycznych na bazie danych po utworzeniu pierwszego klucza
 SELECT * FROM sys.symmetric_keys
 
 DROP SYMMETRIC KEY [Recreatable_Symmetric_Key] 

 CREATE SYMMETRIC KEY [Recreatable_Symmetric_Key] 
	WITH
		KEY_SOURCE = 'Secret_Key_Source_value',
		ALGORITHM = AES_256,
		IDENTITY_VALUE = 'MyIdentity'
	ENCRYPTION BY PASSWORD = 'StrongPassword123!'

 SELECT * FROM sys.symmetric_keys

-- szyfrowanie wra¿liwych danych

OPEN SYMMETRIC KEY [Recreatable_Symmetric_Key]  
DECRYPTION BY PASSWORD = 'StrongPassword123!';

 SELECT 
	 [CustomerID], 
	 [NameStyle], 
	 [Title], 
	 ENCRYPTBYKEY(KEY_GUID('Recreatable_Symmetric_Key'), [FirstName]) AS [FirstName_encrypted],
	 ENCRYPTBYKEY(KEY_GUID('Recreatable_Symmetric_Key'), [MiddleName]) AS [MiddleName_encrypted],
	 ENCRYPTBYKEY(KEY_GUID('Recreatable_Symmetric_Key'), [LastName]) AS [LastName_encrypted],
	 [Suffix], 
	 [CompanyName], 
	 [SalesPerson], 
	 ENCRYPTBYKEY(KEY_GUID('Recreatable_Symmetric_Key'), [EmailAddress]) AS [EmailAddress_encrypted],
	 ENCRYPTBYKEY(KEY_GUID('Recreatable_Symmetric_Key'), [Phone]) AS [Phone_encrypted],
	 [rowguid], 
	 [ModifiedDate]
  FROM [dbo].[Customer]


-- zamykanie klucza szyfruj¹cego
CLOSE SYMMETRIC KEY [Recreatable_Symmetric_Key];
 
select * FROM [dbo].[Customer]

-- zapisanie zaszyfrowanych danych jako varbinary

ALTER TABLE [dbo].[Customer]
ADD [FirstName_encrypted] varbinary(4000),
	[MiddleName_encrypted] varbinary(4000),
	[LastName_encrypted] varbinary(4000),
	[EmailAddress_encrypted] varbinary(4000),
	[Phone_encrypted] varbinary(4000)


OPEN SYMMETRIC KEY [Recreatable_Symmetric_Key]  
DECRYPTION BY PASSWORD = 'StrongPassword123!'

UPDATE [dbo].[Customer]
SET [FirstName_encrypted] = ENCRYPTBYKEY(KEY_GUID('Recreatable_Symmetric_Key'),[FirstName]),
	[MiddleName_encrypted] = ENCRYPTBYKEY(KEY_GUID('Recreatable_Symmetric_Key'), [MiddleName]),
	[LastName_encrypted] = ENCRYPTBYKEY(KEY_GUID('Recreatable_Symmetric_Key'), [LastName]),
	[EmailAddress_encrypted] = ENCRYPTBYKEY(KEY_GUID('Recreatable_Symmetric_Key'), [EmailAddress]),
	[Phone_encrypted] = ENCRYPTBYKEY(KEY_GUID('Recreatable_Symmetric_Key'), [Phone])

CLOSE SYMMETRIC KEY [Recreatable_Symmetric_Key]

---- sprawdzenie danych modyfikowanej tabeli
select * FROM [dbo].[Customer]

----- odszyfrowanie danych
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

--- zamkniêcie klucza, usuniêcie kolumn

CLOSE SYMMETRIC KEY [Recreatable_Symmetric_Key]

ALTER TABLE [dbo].[Customer]
DROP COLUMN [FirstName], [MiddleName], [LastName], [EmailAddress], [Phone]

select * from [dbo].[Customer]

-- lista kluczy symetrycznych na bazie danych po utworzeniu pierwszego klucza
 SELECT * FROM sys.symmetric_keys

 DROP SYMMETRIC KEY [Recreatable_Symmetric_Key] 

 CREATE SYMMETRIC KEY [Recreatable_Symmetric_Key] 
	WITH
		KEY_SOURCE = 'Secret_Key_Source_value',
		ALGORITHM = AES_256,
		IDENTITY_VALUE = 'MyIdentity'
	ENCRYPTION BY PASSWORD = 'StrongPassword123!'

 SELECT * FROM sys.symmetric_keys


-- odszyfrowanie danych

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

--aby utworzyæ odtwarzalny klucz symetryczny, niezbêdne jest posiadanie minimum: password, key_source i identity, symmetric key name




