-- DEMO part 1 KS
-- SRC_DB

-- inicjalna wersja tabeli z danymi

SELECT  *
  FROM [dbo].[Customer]


-- lista kluczy symetrycznych na bazie danych
 SELECT * FROM sys.symmetric_keys


 -- utworzenie klucza symetrycznego potrzebnego do zaszyfrowania danych

 CREATE SYMMETRIC KEY [Simple_Symmetric_Key] 
	WITH
	ALGORITHM = AES_256
	ENCRYPTION BY PASSWORD = 'StrongPassword123!'

-- lista kluczy symetrycznych na bazie danych po utworzeniu pierwszego klucza
 SELECT * FROM sys.symmetric_keys

 -- wskazanie wra¿liwych kolumn do szyfrowania
 SELECT 
	 [CustomerID], 
	 [NameStyle], 
	 [Title], 
	 [FirstName], 
	 [MiddleName], 
	 [LastName], 
	 [Suffix], 
	 [CompanyName], 
	 [SalesPerson], 
	 [EmailAddress], 
	 [Phone], 
	 [rowguid], 
	 [ModifiedDate]
  FROM [dbo].[Customer]

-- szyfrowanie wra¿liwych danych

  OPEN SYMMETRIC KEY [Simple_Symmetric_Key]  
DECRYPTION BY PASSWORD = 'StrongPassword123!';

 SELECT 
	 [CustomerID], 
	 [NameStyle], 
	 [Title], 
	 ENCRYPTBYKEY(KEY_GUID('Simple_Symmetric_Key'), [FirstName]) AS [FirstName_encrypted],
	 ENCRYPTBYKEY(KEY_GUID('Simple_Symmetric_Key'), [MiddleName]) AS [MiddleName_encrypted],
	 ENCRYPTBYKEY(KEY_GUID('Simple_Symmetric_Key'), [LastName]) AS [LastName_encrypted],
	 [Suffix], 
	 [CompanyName], 
	 [SalesPerson], 
	 ENCRYPTBYKEY(KEY_GUID('Simple_Symmetric_Key'), [EmailAddress]) AS [EmailAddress_encrypted],
	 ENCRYPTBYKEY(KEY_GUID('Simple_Symmetric_Key'), [Phone]) AS [Phone_encrypted],
	 [rowguid], 
	 [ModifiedDate]
  FROM [dbo].[Customer]


-- zamykanie klucza szyfruj¹cego
CLOSE SYMMETRIC KEY [Simple_Symmetric_Key];
 
select * FROM [dbo].[Customer]

-- zapisanie zaszyfrowanych danych jako varbinary



ALTER TABLE [dbo].[Customer]
ADD [FirstName_encrypted] varbinary(4000),
	[MiddleName_encrypted] varbinary(4000),
	[LastName_encrypted] varbinary(4000),
	[EmailAddress_encrypted] varbinary(4000),
	[Phone_encrypted] varbinary(4000)


OPEN SYMMETRIC KEY [Simple_Symmetric_Key]  
DECRYPTION BY PASSWORD = 'StrongPassword123!'

UPDATE [dbo].[Customer]
SET [FirstName_encrypted] = ENCRYPTBYKEY(KEY_GUID('Simple_Symmetric_Key'), [FirstName]),
	[MiddleName_encrypted] = ENCRYPTBYKEY(KEY_GUID('Simple_Symmetric_Key'), [MiddleName]),
	[LastName_encrypted] = ENCRYPTBYKEY(KEY_GUID('Simple_Symmetric_Key'), [LastName]),
	[EmailAddress_encrypted] = ENCRYPTBYKEY(KEY_GUID('Simple_Symmetric_Key'), [EmailAddress]),
	[Phone_encrypted] = ENCRYPTBYKEY(KEY_GUID('Simple_Symmetric_Key'), [Phone])

CLOSE SYMMETRIC KEY [Simple_Symmetric_Key]

---- sprawdzenie danych modyfikowanej tabeli
select * FROM [dbo].[Customer]

----- odszyfrowanie danych - otwarcie klucza dzia³a dopóki sesja jest aktywna lub klucz zostanie zamkniêty
----- tabela nie posiada funkcji deszyfruj¹cej wiêc nadal widzimy zaszyfrowane wartoœci, mimo otwartego klucza
OPEN SYMMETRIC KEY [Simple_Symmetric_Key]  
DECRYPTION BY PASSWORD = 'StrongPassword123!'

SELECT * FROM [dbo].[Customer]




----- odszyfrowanie danych part 2, wra¿liwe na varchar/nvarchar, nie podajemy jawnie klucza
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

  ---
   SELECT 
	 CAST(DECRYPTBYKEY([FirstName_encrypted]) AS NVARCHAR(4000)) AS [FirstName]
  FROM [dbo].[Customer]

     SELECT 
	 CAST(DECRYPTBYKEY([FirstName_encrypted]) AS VARCHAR(4000)) AS [FirstName]
  FROM [dbo].[Customer]


--- zamkniêcie klucza, usuniêcie kolumn, usuniêcie klucza

CLOSE SYMMETRIC KEY [Simple_Symmetric_Key]

ALTER TABLE [dbo].[Customer]
DROP COLUMN [FirstName], [MiddleName], [LastName], [EmailAddress], [Phone]

DROP SYMMETRIC KEY [Simple_Symmetric_Key] 

--- odtworzenie klucza
 -- utworzenie klucza symetrycznego potrzebnego do zaszyfrowania danych

CREATE SYMMETRIC KEY [Simple_Symmetric_Key] 
	WITH
	ALGORITHM = AES_256
	ENCRYPTION BY PASSWORD = 'StrongPassword123!'

-- otworzenie nowego klucza
OPEN SYMMETRIC KEY [Simple_Symmetric_Key]  
	DECRYPTION BY PASSWORD = 'StrongPassword123!'

-- próba odszyfrowania danych
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

  -- podstawowy klucz nie jest odtwarzalny
  -- ryzyko utraty danych

