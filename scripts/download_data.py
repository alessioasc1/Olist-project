import os
import zipfile
from kaggle.api.kaggle_api_extended import KaggleApi

def main():
    dataset_id = "olistbr/brazilian-ecommerce"
    download_path = "data"
    extract_path = "data/raw_csv"

    # Assicura che le cartelle esistano localmente all'esecuzione
    os.makedirs(extract_path, exist_ok=True)

    print("Autenticazione su Kaggle in corso...")
    api = KaggleApi()
    api.authenticate()

    # Controllo idempotenza: se ci sono già i file, non riscaricare
    existing_csvs = [f for f in os.listdir(extract_path) if f.endswith('.csv')]
    if len(existing_csvs) >= 9:
        print(f"I file CSV sono già presenti in '{extract_path}'. Salto il download.")
        return

    print(f"Download del dataset '{dataset_id}' in corso...")
    api.dataset_download_files(dataset_id, path=download_path, unzip=False)
    
    zip_file_path = os.path.join(download_path, "brazilian-ecommerce.zip")
    
    print(f"Estrazione dei file in '{extract_path}'...")
    with zipfile.ZipFile(zip_file_path, 'r') as zip_ref:
        zip_ref.extractall(extract_path)
        
    os.remove(zip_file_path)
    print("Download ed estrazione completati con successo!")

if __name__ == "__main__":
    main()