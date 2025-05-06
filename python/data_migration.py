import time

from sqlalchemy import VARBINARY

import common


def data_migration():
    """
    Migrates tables from source to target SQL Server database using token authentication.
    
    Extracts all tables from source 'dbo' schema with special handling for encrypted 
    columns (identified by '_encrypted'). Prints progress information and execution time.
    
    Returns
    -------
    None
    """

    start_time = time.time()

    src_server = ""
    src_database = "SRC_DB"

    trg_server = ""
    trg_database = "TRG_DB"
    
    trg_connection = common.sql_engine_token(server=trg_server, database=trg_database)

    with common.sql_engine_token(server=src_server, database=src_database) as src_connection:
        tables_DF = common.get_table_names(connection=src_connection, schema_name="dbo")
        
        print(f"Tables to migrate: {len(tables_DF)}")
        
        tables_DF.sort_values(by=["TABLE_NAME"], inplace=True)
        for schema_name, table_name in tables_DF.values:
            print(f"Reading table {schema_name}.{table_name}")
            table_df = common.read_adb(sql_engine=src_connection, schema_name=schema_name, object_name=table_name)
            print(table_df.head(10))

            table_df.to_sql(
                name=table_name,
                con=trg_connection,
                schema=schema_name,
                if_exists="replace",
                index=False,
                dtype={
                    col: VARBINARY(4000)
                    for col in table_df.columns  
                    if "_encrypted" in col
                },
            )
            trg_connection.commit()
            print(f"Table {schema_name}.{table_name} migrated successfully")
    trg_connection.close()
    end_time = time.time()
    print(f"Execution time: {end_time - start_time:.2f} seconds")

if __name__ == "__main__":
    data_migration()
