SELECT * FROM [dbo].[Customer]

EXEC EncryptAndReplaceColumns
	@SchemaName = 'dbo',
    @TableName = 'Customer',
    @ColumnsToEncrypt = 'CustomerID,NameStyle,Title,Suffix,CompanyName,SalesPerson,rowguid,ModifiedDate',
    @KeyName = 'Additional_Symmetric_Key',
    @KeyPassword = 'TopSecretPassword123!'

SELECT * FROM [dbo].[Customer]

--- test
OPEN SYMMETRIC KEY Additional_Symmetric_Key
DECRYPTION BY PASSWORD = 'TopSecretPassword123!'

OPEN SYMMETRIC KEY Recreatable_Symmetric_Key
DECRYPTION BY PASSWORD = 'StrongPassword123!'


SELECT * FROM [dbo].[VW_Customer]