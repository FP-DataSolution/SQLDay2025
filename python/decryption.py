import pandas as pd
from sqlalchemy import text

import common


def decrypt_data():
    """
    Decrypts customer data from Azure SQL Database using symmetric keys from Azure Key Vault.
    
    Returns
    -------
    pandas.DataFrame
        DataFrame with decrypted customer data from VW_Customer view.
    
    Raises
    ------
    Exception
        If database connection or decryption process fails.
    """

    trg_connection = common.sql_engine_token(
        "", 
        "TRG_DB"
    )
    
    kv_url = 'https://placeholder.vault.azure.net'
    secret_keys = [
        "Recreatable-Symmetric-Key-Name", "Recreatable-Symmetric-Key-Password",
        "Additional-Symmetric-Key-Name", "Additional-Symmetric-Key-Password"
    ]
    secrets = common.get_kv_secrets(kv_url=kv_url, secret_names=secret_keys)
    
    key_sql = f"""
    OPEN SYMMETRIC KEY {secrets["Recreatable-Symmetric-Key-Name"]}
    DECRYPTION BY PASSWORD = '{secrets["Recreatable-Symmetric-Key-Password"]}'
    
    OPEN SYMMETRIC KEY {secrets["Additional-Symmetric-Key-Name"]}
    DECRYPTION BY PASSWORD = '{secrets["Additional-Symmetric-Key-Password"]}'
    """
    
    with trg_connection:
        try:
            trg_connection.execute(text(key_sql))
            results = trg_connection.execute(text("SELECT * FROM dbo.VW_Customer"))
            return pd.DataFrame(results)
        except Exception:
            print(f"Error during query execution")
            raise

if __name__ == "__main__":
    print(decrypt_data())