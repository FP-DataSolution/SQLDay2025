import struct

import pandas as pd
import pyodbc
import requests
import sqlalchemy
from azure.identity import DefaultAzureCredential


def sql_engine_token(server: str, database: str) -> sqlalchemy.engine.Connection:
    """
    Create SQL connection using Azure AD token authentication.
    
    Parameters
    ----------
    server : str
        SQL Server hostname
    database : str
        Database name
        
    Returns
    -------
    sqlalchemy.engine.Connection
        Authenticated connection object
    """

    
    SQL_COPT_SS_ACCESS_TOKEN = 1256
    TOKEN_URL = (
        "https://database.windows.net/"  
    )

    connection_string = (
        f"mssql+pyodbc://@{server}/{database}?driver=ODBC+Driver+17+for+SQL+Server"
    )

    engine = sqlalchemy.create_engine(connection_string)

    azure_credentials = DefaultAzureCredential()

    @sqlalchemy.event.listens_for(engine, "do_connect")
    def provide_token(dialect, conn_rec, cargs, cparams):
        # remove the "Trusted_Connection" parameter that SQLAlchemy adds
        cargs[0] = cargs[0].replace(";Trusted_Connection=Yes", "")

        raw_token = azure_credentials.get_token(TOKEN_URL).token.encode("utf-16-le")
        token_struct = struct.pack(f"<I{len(raw_token)}s", len(raw_token), raw_token)

        cparams["attrs_before"] = {SQL_COPT_SS_ACCESS_TOKEN: token_struct}

    connection = engine.connect()
    return connection




def read_adb(sql_engine: object, schema_name: str, object_name: str) -> pd.DataFrame:
    """
    Read data from a database table into a pandas DataFrame.
    
    Parameters
    ----------
    sql_engine : object
        SQLAlchemy connection object
    schema_name : str
        Schema name containing the table
    object_name : str
        Table name to query
    
    Returns
    -------
    pd.DataFrame
        Data from the specified table
    """
    query = f"SELECT * FROM {schema_name}.{object_name}"
    try:
        results_DF = pd.read_sql_query(sql=query, con=sql_engine)
        return results_DF

    except pyodbc.Error as ex:
        print(f"Database connection error: {ex}")


def get_table_names(connection: object, schema_name: str) -> pd.DataFrame:
    """
    Get all tables from specified schema.
    
    Parameters
    ----------
    connection : object
        Database connection
    schema_name : str
        Schema name
        
    Returns
    -------
    pd.DataFrame
        DataFrame with schema and table names
    """
    query = f"SELECT TABLE_SCHEMA, TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='BASE TABLE' AND TABLE_SCHEMA='{schema_name}'"
    try:
        tables_DF = pd.read_sql_query(query, connection)
        return tables_DF

    except pyodbc.Error as ex:
        print(f"Database connection error: {ex}")


def get_kv_secrets(kv_url: str, secret_names: list[str]) -> dict[str, str]:
    """
    Retrieve multiple secrets from Azure Key Vault.
    
    Parameters
    ----------
    kv_url : str
        Azure Key Vault URL
    secret_names : list[str]
        Secret names to retrieve
        
    Returns
    -------
    dict[str, str]
        Dictionary of secret names to values
        
    Raises
    ------
    Exception
        If secret retrieval fails
    """

    credential = DefaultAzureCredential()
    token = credential.get_token("https://vault.azure.net/.default").token
    headers = {"Authorization": f"Bearer {token}"}
    secret_name_dict = {}
    for secret_name in secret_names:
        response = requests.get(f"{kv_url}/secrets/{secret_name}?api-version=7.3", headers=headers)

        if response.status_code == 200:
            secret_value = response.json()["value"]
            secret_name_dict[secret_name] = secret_value
        else:
            raise Exception(f"Failed to retrieve secret: {response.status_code} - {response.text}")
    
    return secret_name_dict

