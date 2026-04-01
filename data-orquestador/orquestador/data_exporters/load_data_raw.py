from mage_ai.settings.repo import get_repo_path
from mage_ai.io.config import ConfigFileLoader
from mage_ai.io.postgres import Postgres
from os import path
import pandas as pd
import gc
import math

if 'data_exporter' not in globals():
    from mage_ai.data_preparation.decorators import data_exporter


@data_exporter
def export_data_to_postgres(urls, **kwargs) -> None:
    schema_name = 'raw' 
    table_name = 'ny_taxi_trips' 
    config_path = path.join(get_repo_path(), 'io_config.yaml')
    config_profile = 'default'

    # Reducimos el chunk para asegurar la estabilidad del kernel
    tamano_chunk = 100000 
    
    es_primera_insercion = True

    for url in urls:
        print(f"Procesando archivo: {url}")
        try:
            
            df_temp = pd.read_parquet(url)
            df_temp.columns = df_temp.columns.str.lower()
            
            total_filas = df_temp.shape[0]
            num_chunks = math.ceil(total_filas / tamano_chunk)
            
            inicio = 0
            fin = tamano_chunk

            with Postgres.with_config(ConfigFileLoader(config_path, config_profile)) as loader:
                for i in range(num_chunks):
                    
                    df_chunk = df_temp.iloc[inicio:fin].copy()
                    
                    
                    df_chunk = df_chunk.astype(str)
                    
                    politica_insercion = 'replace' if es_primera_insercion else 'append'
                    
                    loader.export(
                        df_chunk,
                        schema_name,
                        table_name,
                        index=False,
                        if_exists=politica_insercion, 
                    )
                    
                    print(f"    - Chunk {i+1}/{num_chunks} insertado correctamente.")
                    
                    inicio = fin
                    fin += tamano_chunk
                    es_primera_insercion = False 
                    
                    
                    del df_chunk
                    gc.collect()

            print(f"Éxito cargando mes completo: {url}\n")
            
            
            del df_temp
            gc.collect() 
            
        except Exception as e:
            import traceback
            print(f"❌ Error crítico al procesar {url}:")
            print(f"   Tipo: {type(e).__name__}")
            print(f"   Mensaje: {e}")
            print(f"   Traceback completo:")
            traceback.print_exc()
            print("─" * 60)