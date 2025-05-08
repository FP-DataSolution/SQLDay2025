CREATE OR ALTER PROCEDURE EncryptAndReplaceColumns
    @SchemaName NVARCHAR(128),
    @TableName NVARCHAR(128),
    @ColumnsToEncrypt NVARCHAR(MAX),
    @KeyName NVARCHAR(128),
    @KeyPassword NVARCHAR(256)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE 
        @ColumnName NVARCHAR(128),
        @EncryptedColumnName NVARCHAR(128),
        @Pos INT,
        @SQL NVARCHAR(MAX) = '',
        @OriginalColumns NVARCHAR(MAX) = @ColumnsToEncrypt

    -- Step 1: Dodaj zaszyfrowane kolumny
    SET @Pos = CHARINDEX(',', @ColumnsToEncrypt)
    WHILE LEN(@ColumnsToEncrypt) > 0
    BEGIN
        IF @Pos = 0
            SET @ColumnName = LTRIM(RTRIM(@ColumnsToEncrypt))
        ELSE
            SET @ColumnName = LTRIM(RTRIM(LEFT(@ColumnsToEncrypt, @Pos - 1)))

        SET @EncryptedColumnName = QUOTENAME(@ColumnName + '_encrypted')
        SET @SQL += 'IF COL_LENGTH(''' + @SchemaName + '.' + @TableName + ''', ''' + @ColumnName + '_encrypted'') IS NULL ' +
                    'ALTER TABLE ' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName) + 
                    ' ADD ' + @EncryptedColumnName + ' VARBINARY(8000);' + CHAR(13)

        IF @Pos = 0 
            SET @ColumnsToEncrypt = ''
        ELSE
        BEGIN
            SET @ColumnsToEncrypt = RIGHT(@ColumnsToEncrypt, LEN(@ColumnsToEncrypt) - @Pos)
            SET @Pos = CHARINDEX(',', @ColumnsToEncrypt)
        END
    END
    EXEC sp_executesql @SQL

    -- Step 2: Szyfruj dane
    SET @ColumnsToEncrypt = @OriginalColumns
    SET @SQL = 'OPEN SYMMETRIC KEY [' + @KeyName + '] DECRYPTION BY PASSWORD = ''' + @KeyPassword + ''';' + CHAR(13)
    SET @Pos = CHARINDEX(',', @ColumnsToEncrypt)

    WHILE LEN(@ColumnsToEncrypt) > 0
    BEGIN
        IF @Pos = 0
            SET @ColumnName = LTRIM(RTRIM(@ColumnsToEncrypt))
        ELSE
            SET @ColumnName = LTRIM(RTRIM(LEFT(@ColumnsToEncrypt, @Pos - 1)))

        SET @EncryptedColumnName = QUOTENAME(@ColumnName + '_encrypted')
        SET @SQL += 'UPDATE ' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName) + 
                    ' SET ' + @EncryptedColumnName + ' = ENCRYPTBYKEY(KEY_GUID(''' + @KeyName + '''), CONVERT(VARBINARY(4000), CAST(' + QUOTENAME(@ColumnName) + ' AS NVARCHAR(4000))));' + CHAR(13)

        IF @Pos = 0 
            SET @ColumnsToEncrypt = ''
        ELSE
        BEGIN
            SET @ColumnsToEncrypt = RIGHT(@ColumnsToEncrypt, LEN(@ColumnsToEncrypt) - @Pos)
            SET @Pos = CHARINDEX(',', @ColumnsToEncrypt)
        END
    END
    SET @SQL += 'CLOSE SYMMETRIC KEY [' + @KeyName + '];' + CHAR(13)

    -- Step 3: Usuń stare kolumny
    SET @ColumnsToEncrypt = @OriginalColumns
    SET @Pos = CHARINDEX(',', @ColumnsToEncrypt)
    WHILE LEN(@ColumnsToEncrypt) > 0
    BEGIN
        IF @Pos = 0
            SET @ColumnName = LTRIM(RTRIM(@ColumnsToEncrypt))
        ELSE
            SET @ColumnName = LTRIM(RTRIM(LEFT(@ColumnsToEncrypt, @Pos - 1)))

        SET @SQL += 'IF COL_LENGTH(''' + @SchemaName + '.' + @TableName + ''', ''' + @ColumnName + ''') IS NOT NULL ' +
                    'ALTER TABLE ' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName) + 
                    ' DROP COLUMN ' + QUOTENAME(@ColumnName) + ';' + CHAR(13)

        IF @Pos = 0 
            SET @ColumnsToEncrypt = ''
        ELSE
        BEGIN
            SET @ColumnsToEncrypt = RIGHT(@ColumnsToEncrypt, LEN(@ColumnsToEncrypt) - @Pos)
            SET @Pos = CHARINDEX(',', @ColumnsToEncrypt)
        END
    END
    EXEC sp_executesql @SQL

    -- Step 4: Twórz widoki
    DECLARE 
        @SqlQuery NVARCHAR(MAX),
        @int INT,
        @no_of_tables INT,
        @counter INT = 0

    DECLARE @objects AS TABLE (
        rn INT,
        schema_name VARCHAR(MAX),
        table_name VARCHAR(MAX)
    )

    INSERT INTO @objects
    SELECT ROW_NUMBER() OVER (ORDER BY t.name) as RN,
           s.name AS schema_name,
           t.name AS table_name
    FROM sys.schemas s
    INNER JOIN sys.tables t ON s.schema_id = t.schema_id
    WHERE s.name = @SchemaName

    SET @int = (SELECT COUNT(*) FROM @objects)
    SET @no_of_tables = @int

    WHILE @int > 0
    BEGIN
        SET @TableName = (SELECT TOP 1 table_name FROM @objects ORDER BY RN)
        SET @SchemaName = (SELECT TOP 1 schema_name FROM @objects ORDER BY RN)

        SET @SqlQuery = '
        CREATE OR ALTER VIEW ['+ @SchemaName +'].[VW_'+ @TableName +'] AS
        SELECT '

        SELECT @SqlQuery = @SqlQuery +
            CASE
                WHEN COLUMN_NAME LIKE '%_encrypted%' THEN
                    'CAST(DECRYPTBYKEY(['+ COLUMN_NAME +']) AS NVARCHAR(4000)) AS [' + REPLACE(COLUMN_NAME, '_encrypted', '') + '],'
                ELSE
                    ' [' + COLUMN_NAME + '],'
            END
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_NAME = @TableName AND TABLE_SCHEMA = @SchemaName

        SET @SqlQuery = LEFT(@SqlQuery, LEN(@SqlQuery) - 1) + ' FROM [' +@SchemaName + '].['+ @TableName +']'

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
        SET @int = (SELECT COUNT(*) FROM @objects)
    END

    SELECT CAST(@counter AS VARCHAR) + '/' + CAST(@no_of_tables AS VARCHAR) + ' views created.' AS INFO
END
