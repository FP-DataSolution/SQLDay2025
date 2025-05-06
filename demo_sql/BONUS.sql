SELECT
*
FROM [dbo].[Customer]
 
 

--- step 1: dodajemy kolumny	
	DECLARE 
    @TableName NVARCHAR(128) = 'Customer',
    @ColumnsToEncrypt NVARCHAR(MAX) = 'CustomerID,NameStyle,Title,Suffix,CompanyName,SalesPerson,rowguid,ModifiedDate'

DECLARE 
    @ColumnName NVARCHAR(128),
    @SQL NVARCHAR(MAX) = '',
    @Pos INT,
    @EncryptedColumnName NVARCHAR(128)

SET @Pos = CHARINDEX(',', @ColumnsToEncrypt)
WHILE LEN(@ColumnsToEncrypt) > 0
BEGIN
    IF @Pos = 0
        SET @ColumnName = LTRIM(RTRIM(@ColumnsToEncrypt))
    ELSE
        SET @ColumnName = LTRIM(RTRIM(LEFT(@ColumnsToEncrypt, @Pos - 1)))

    SET @EncryptedColumnName = QUOTENAME(@ColumnName + '_encrypted')
    SET @SQL += 'IF COL_LENGTH(''' + @TableName + ''', ''' + @ColumnName + '_encrypted'') IS NULL ' +
                'ALTER TABLE ' + QUOTENAME(@TableName) + ' ADD ' + @EncryptedColumnName + ' VARBINARY(8000);' + CHAR(13)

    IF @Pos = 0 
        SET @ColumnsToEncrypt = ''
    ELSE
    BEGIN
        SET @ColumnsToEncrypt = RIGHT(@ColumnsToEncrypt, LEN(@ColumnsToEncrypt) - @Pos)
        SET @Pos = CHARINDEX(',', @ColumnsToEncrypt)
    END
END

EXEC sp_executesql @SQL

--- step 2: szyfrujemy dane

DECLARE 
    @TableName NVARCHAR(128) = 'Customer',
    @ColumnsToEncrypt NVARCHAR(MAX) = 'CustomerID,NameStyle,Title,Suffix,CompanyName,SalesPerson,rowguid,ModifiedDate',
    @KeyName NVARCHAR(128) = 'Additional_Symmetric_Key',
    @KeyPassword NVARCHAR(256) = 'TopSecretPassword123!'

DECLARE 
    @ColumnName NVARCHAR(128),
    @EncryptedColumnName NVARCHAR(128),
    @Pos INT,
    @SQL NVARCHAR(MAX) = ''

-- Otwórz klucz
SET @SQL = 'OPEN SYMMETRIC KEY [' + @KeyName + '] DECRYPTION BY PASSWORD = ''' + @KeyPassword + ''';' + CHAR(13)

-- Szyfrowanie
SET @Pos = CHARINDEX(',', @ColumnsToEncrypt)
WHILE LEN(@ColumnsToEncrypt) > 0
BEGIN
    IF @Pos = 0
        SET @ColumnName = LTRIM(RTRIM(@ColumnsToEncrypt))
    ELSE
        SET @ColumnName = LTRIM(RTRIM(LEFT(@ColumnsToEncrypt, @Pos - 1)))

    SET @EncryptedColumnName = QUOTENAME(@ColumnName + '_encrypted')

    SET @SQL += 'UPDATE ' + QUOTENAME(@TableName) + ' SET ' + @EncryptedColumnName + 
                ' = ENCRYPTBYKEY(KEY_GUID(''' + @KeyName + '''), CONVERT(VARBINARY(4000), CAST(' + QUOTENAME(@ColumnName) + ' AS NVARCHAR(4000))));' + CHAR(13)

    IF @Pos = 0 
        SET @ColumnsToEncrypt = ''
    ELSE
    BEGIN
        SET @ColumnsToEncrypt = RIGHT(@ColumnsToEncrypt, LEN(@ColumnsToEncrypt) - @Pos)
        SET @Pos = CHARINDEX(',', @ColumnsToEncrypt)
    END
END

-- Zamknij klucz
SET @SQL += 'CLOSE SYMMETRIC KEY [' + @KeyName + '];' + CHAR(13)

-- Usuń oryginalne kolumny
SET @ColumnsToEncrypt = 'CustomerID,NameStyle,Title,Suffix,CompanyName,SalesPerson,rowguid,ModifiedDate'
SET @Pos = CHARINDEX(',', @ColumnsToEncrypt)
WHILE LEN(@ColumnsToEncrypt) > 0
BEGIN
    IF @Pos = 0
        SET @ColumnName = LTRIM(RTRIM(@ColumnsToEncrypt))
    ELSE
        SET @ColumnName = LTRIM(RTRIM(LEFT(@ColumnsToEncrypt, @Pos - 1)))

    SET @SQL += 'IF COL_LENGTH(''' + @TableName + ''', ''' + @ColumnName + ''') IS NOT NULL ' +
                'ALTER TABLE ' + QUOTENAME(@TableName) + ' DROP COLUMN ' + QUOTENAME(@ColumnName) + ';' + CHAR(13)

    IF @Pos = 0 
        SET @ColumnsToEncrypt = ''
    ELSE
    BEGIN
        SET @ColumnsToEncrypt = RIGHT(@ColumnsToEncrypt, LEN(@ColumnsToEncrypt) - @Pos)
        SET @Pos = CHARINDEX(',', @ColumnsToEncrypt)
    END
END

EXEC sp_executesql @SQL


--- final step
OPEN SYMMETRIC KEY Additional_Symmetric_Key
DECRYPTION BY PASSWORD = 'TopSecretPassword123!'

OPEN SYMMETRIC KEY Recreatable_Symmetric_Key
DECRYPTION BY PASSWORD = 'StrongPassword123!'


SELECT * FROM [dbo].[VW_Customer]