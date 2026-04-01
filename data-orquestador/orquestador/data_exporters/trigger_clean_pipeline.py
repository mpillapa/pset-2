from mage_ai.orchestration.triggers.api import trigger_pipeline

if 'data_exporter' not in globals():
    from mage_ai.data_preparation.decorators import data_exporter

@data_exporter
def trigger_clean_model(*args, **kwargs):
    
    nombre_pipeline_clean = 'data_clean'
    
    print(f"Iniciando el trigger para el pipeline: {nombre_pipeline_clean}...")
    
    trigger_pipeline(
        nombre_pipeline_clean,
        variables={}, 
        check_status=False,
        error_on_failure=True,
    )
    
    print("La capa Clean se está construyendo.")