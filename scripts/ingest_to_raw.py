import os
import glob
import pandas as pd
from dotenv import load_dotenv
import snowflake.connector

# Carica le credenziali dal file .env
load_dotenv()

def get_snowflake_connection():
    return snowflake.connector.connect(
        user=os.getenv("SNOWFLAKE_USER"),
        password=os.getenv("SNOWFLAKE_PASSWORD"),
        account=os.getenv("SNOWFLAKE_ACCOUNT"),
        warehouse=os.getenv("SNOWFLAKE_WAREHOUSE"),
        database="DATA_ACADEMY",
        schema="RAW"
    )

def main():
    conn = get_snowflake_connection()
    cursor = conn.cursor()

    # Percorso dove si trovano i 9 CSV
    csv_files = glob.glob("data/raw_csv/*.csv")
    
    if not csv_files:
        print("Nessun file CSV trovato in data/raw_csv/. Esegui prima lo script di download!")
        return

    # Creiamo uno Stage interno a Snowflake per ospitare temporaneamente i file caricati con PUT
    cursor.execute("CREATE STAGE IF NOT EXISTS olist_stage;")

    for file_path in csv_files:
        file_name = os.path.basename(file_path)
        # Riconduciamo il nome del file a un formato pulito per la tabella (es. olist_orders_dataset -> olist_orders)
        table_name = file_name.replace(".csv", "").replace("_dataset", "").replace("olist_", "").upper()
        
        print(f"\n--- Elaborazione tabella: {table_name} ---")

        # Leggiamo solo la prima riga del CSV con pandas per estrarre i nomi delle colonne
        df_sample = pd.read_csv(file_path, nrows=1)
        columns = df_sample.columns.tolist()

        # Generiamo la query DDL per creare la tabella in modo IDEMPOTENTE (DROP + CREATE)
        # Tutte le colonne sorgente saranno VARCHAR, più i 2 campi di metadati richiesti
        col_definitions = [f'"{col.upper()}" VARCHAR' for col in columns]
        col_definitions.append('"_LOADED_AT" TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()')
        col_definitions.append('"_SOURCE_FILE" VARCHAR')
        
        # Dividiamo i comandi in due query separate per evitare l'errore multi-statement
        drop_table_query = f'DROP TABLE IF EXISTS {table_name};'
        
        create_table_query = f"""
        CREATE TABLE {table_name} (
            {', '.join(col_definitions)}
        );
        """
        
        print(f"Eliminazione (se esiste) e creazione tabella {table_name} in corso...")
        # Eseguiamo prima il DROP
        cursor.execute(drop_table_query)
        # Poi eseguiamo il CREATE
        cursor.execute(create_table_query)

        # Fase 1: Comando PUT per caricare il file locale nello Stage di Snowflake
        # Usiamo auto_compress=True per velocizzare il trasferimento
        print(f"Esecuzione PUT di {file_name} nello stage...")
        cursor.execute(f"PUT file://{file_path} @olist_stage auto_compress=true;")

        # Fase 2: Esecuzione COPY INTO per caricare i dati dallo stage alla tabella RAW
        # Mappiamo le colonne del CSV alle colonne della tabella, iniettando il nome del file nei metadati
        file_col_mappings = [f"${i+1}" for i in range(len(columns))]
        file_col_mappings.append("CURRENT_TIMESTAMP()")
        file_col_mappings.append("METADATA$FILENAME") # Funzione nativa di Snowflake per tracciare il file d'origine

        copy_query = f"""
        COPY INTO {table_name}
        FROM (
            SELECT {', '.join(file_col_mappings)}
            FROM @olist_stage/{file_name}.gz
        )
        FILE_FORMAT = (
            TYPE = 'CSV'
            FIELD_OPTIONALLY_ENCLOSED_BY = '"'
            SKIP_HEADER = 1
            ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE
        );
        """
        print(f"Esecuzione COPY INTO per {table_name}...")
        cursor.execute(copy_query)
        print(f"Tabella {table_name} popolata con successo!")

    cursor.close()
    conn.close()
    print("\n🚀 Ingestione nel layer RAW completata!")

if __name__ == "__main__":
    main()