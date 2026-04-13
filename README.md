# Arquitectura ELT: Análisis de Datos Históricos de NY Taxi (2015-2025)

## Descripción del Proyecto y Cumplimiento de Requisitos

Este proyecto implementa una solución de ingeniería de datos end-to-end basada en una arquitectura ELT (Extract, Load, Transform). El objetivo principal es la extracción, almacenamiento y modelado dimensional de los registros de viajes de taxis amarillos de Nueva York provistos por la Taxi and Limousine Commission (TLC) para el periodo 2015-2025.

El presente proyecto cumple a cabalidad con todos los requerimientos solicitados en el documento de evaluación. Se desarrollaron las dos tuberías de datos exigidas, orquestadas y automatizadas. Adicional al código fuente de la infraestructura, se adjunta un Jupyter Notebook y evidencia fotográfica (capturas de pantalla) que permiten validar la correcta ejecución de los procesos, el levantamiento de los servicios y la integridad de los datos en la base de datos. Asimismo, se incluye el diccionario de datos oficial proporcionado por la TLC (`dictionary/data_dictionary_trip_records_yellow.pdf`), el cual fue utilizado como referencia estricta para la construcción, tipificación y estandarización de las dimensiones del modelo.



## Complejidad Técnica e Ingesta Masiva

El mayor desafío técnico y logro principal de este proyecto radicó en la ingesta masiva de datos históricos. Las limitaciones físicas de memoria (RAM) al procesar archivos Parquet de gran volumen requirieron abandonar los enfoques tradicionales de carga en memoria.

Para lograr la carga exitosa y estable de **801,553,240 registros** en la base de datos, se implementaron las siguientes estrategias de ingeniería:

- **Procesamiento por Chunks:** Lectura e inserción iterativa de datos en fragmentos de 100,000 filas para evitar el colapso del contenedor por errores de Out Of Memory (OOM). Tras cada inserción se fuerza la recolección de basura (`gc.collect()`) para liberar memoria de inmediato.
- **Manejo de Schema Drift:** Implementación de alineación dinámica de esquemas entre años, tomando como base el archivo más reciente (2025) para estandarizar las columnas de años anteriores, rellenando con valores nulos aquellas variables introducidas recientemente (e.g., `cbd_congestion_fee`, presente únicamente a partir de 2025).
- **Carga Incremental:** En la fase de transformación, la tabla de hechos fue construida mediante bucles PL/pgSQL nativos en la base de datos, procesando un año a la vez para proteger el registro de transacciones (WAL) del motor SQL y garantizar la estabilidad del proceso.

El análisis exploratorio previo —documentado en el Jupyter Notebook— fue fundamental para detectar estas inconsistencias de esquema y anomalías de calidad (fechas con año 2088, distancias negativas) antes de diseñar los filtros de limpieza.



## Tecnologías Utilizadas

| Componente | Tecnología |
|---|---|
| Orquestación | Mage.ai |
| Data Warehouse | PostgreSQL 13 |
| UI de Base de Datos | pgAdmin 4 |
| Infraestructura | Docker y Docker Compose |
| Lenguaje (Extracción) | Python (Pandas, PyArrow, FastParquet, SQLAlchemy) |
| Lenguaje (Transformación) | SQL nativo (PL/pgSQL) |



## Estructura del Repositorio

```
pset-2/
├── docker-compose.yaml             # Definición de los 3 servicios Docker
├── requirements.txt                # Dependencias Python del proyecto
├── .gitignore
├── LICENSE
│
├── data-orquestador/               # Volumen montado en el contenedor de Mage.ai
│   └── orquestador/                # Proyecto Mage.ai
│       ├── io_config.yaml          # Configuración de conexiones (PostgreSQL, etc.)
│       ├── pipelines/
│       │   ├── data_raw/           # Pipeline de ingesta (Python)
│       │   └── data_clean/         # Pipeline de transformación (SQL)
│       ├── data_loaders/
│       │   ├── extract_data_raw.py # Generación de URLs TLC (2015-2025)
│       │   ├── fact_trips.sql      # Carga y limpieza de la tabla de hechos
│       │   ├── dim_vendor.sql      # Dimensión de proveedores
│       │   ├── dim_payment_type.sql# Dimensión de métodos de pago
│       │   └── dim_location.sql    # Dimensión de ubicaciones
│       ├── data_exporters/
│       │   ├── load_data_raw.py    # Exportación a esquema raw (chunking)
│       │   └── trigger_clean_pipeline.py # Disparador event-driven
│       └── transformers/
│
├── dictionary/
│   └── data_dictionary_trip_records_yellow.pdf  # Diccionario oficial TLC
│
├── notebooks/
│   └── pruebas_lab2.ipynb          # Análisis exploratorio y validación
│
└── screenshots/                    # Evidencia de ejecución (15 capturas)
    ├── carga en mage*.png          # Progreso de carga en Mage.ai
    ├── trigger_clean_pipeline.png  # Trigger event-driven
    ├── fact_trips_mage.png         # Tabla de hechos en Mage.ai
    ├── *_mage.png                  # Dimensiones en Mage.ai
    ├── *_pgadmin.png               # Tablas validadas en pgAdmin
    └── cantidad_datos_pgadmin.png  # Conteo total de registros
```



## Instrucciones de Despliegue y Ejecución

### Prerrequisitos
- Docker Desktop instalado y en ejecución.
- Al menos 16 GB de RAM disponibles para el proceso de ingesta masiva.

### Pasos

1. **Clonar el repositorio** y acceder al directorio raíz del proyecto:
   ```bash
   git clone <url-del-repositorio>
   cd pset-2
   ```

2. **Levantar la infraestructura** mediante Docker Compose:
   ```bash
   docker-compose up -d
   ```
   Esto levanta tres servicios:
   - `data-warehouse`: PostgreSQL 13 (puerto `5432`)
   - `warehouse-ui`: pgAdmin 4 (puerto `9000`)
   - `orquestador`: Mage.ai (puerto `6789`)

3. **Acceder a las interfaces gráficas:**
   - **Mage.ai:** [http://localhost:6789](http://localhost:6789)
   - **pgAdmin:** [http://localhost:9000](http://localhost:9000)

4. **Ejecutar los pipelines** desde la interfaz de Mage.ai en el siguiente orden:
   - Ejecutar el pipeline `data_raw`. Al completarse exitosamente, el trigger event-driven lanzará automáticamente el pipeline `data_clean`.



## Estructura de Pipelines (Orquestación)

El flujo de trabajo está dividido exactamente en las dos tuberías solicitadas:

### Pipeline 1: `data_raw` — Ingesta

Tubería basada en Python que implementa el flujo ETL de extracción y carga cruda:

```
extract_data_raw.py  →  load_data_raw.py  →  trigger_clean_pipeline.py
```

- **`extract_data_raw.py`**: Genera dinámicamente las URLs de descarga de los archivos Parquet de la TLC para cada mes del periodo 2015-2025 (132 archivos en total).
- **`load_data_raw.py`**: Descarga cada archivo, estandariza nombres de columnas (minúsculas), alinea el esquema al del año 2025 y carga los datos en el esquema `raw` de PostgreSQL en chunks de 100,000 filas. Utiliza la estrategia `replace` para el primer chunk y `append` para los subsiguientes, con recolección de basura forzada entre iteraciones.
- **`trigger_clean_pipeline.py`**: Dispara el pipeline `data_clean` mediante un evento al terminar la ingesta exitosamente.

### Pipeline 2: `data_clean` — Transformación

Tubería basada puramente en bloques SQL que ejecuta la transformación dimensional:

```
dim_payment_type.sql  ──┐
dim_vendor.sql          ├──→  fact_trips.sql
dim_location.sql      ──┘
```

- Las dimensiones se construyen en paralelo con valores controlados y estandarizados según el diccionario de datos oficial.
- `fact_trips.sql` aplica tipificación estricta, filtra registros con anomalías lógicas (distancias negativas o nulas, fechas fuera del rango 2015-2025) y calcula la duración del viaje en minutos.



## Modelo Dimensional

La capa analítica final (`clean`) está estructurada bajo un esquema de estrella (*Star Schema*) procesado íntegramente dentro del motor PostgreSQL:

### `fact_trips` — Tabla de Hechos

| Columna | Tipo | Descripción |
|---|---|---|
| `trip_id` | BIGINT | Identificador único generado con ROW_NUMBER() |
| `vendor_id` | INTEGER | FK → dim_vendor |
| `payment_type` | INTEGER | FK → dim_payment_type |
| `pickup_location_id` | INTEGER | FK → dim_location (origen) |
| `dropoff_location_id` | INTEGER | FK → dim_location (destino) |
| `pickup_datetime` | TIMESTAMP | Fecha y hora de inicio del viaje |
| `dropoff_datetime` | TIMESTAMP | Fecha y hora de fin del viaje |
| `trip_distance` | NUMERIC | Distancia del viaje en millas |
| `passenger_count` | INTEGER | Número de pasajeros |
| `total_amount` | NUMERIC | Monto total cobrado |
| `trip_duration_minutes` | NUMERIC | Duración calculada del viaje |

### `dim_vendor` — Proveedores

| vendor_id | vendor_name |
|---|---|
| 1 | Creative Mobile Technologies |
| 2 | VeriFone Inc. |
| 3 | Myle Technologies |
| 4 | Helix |

### `dim_payment_type` — Métodos de Pago

| payment_type_id | payment_description |
|---|---|
| 1 | Credit card |
| 2 | Cash |
| 3 | No charge |
| 4 | Dispute |
| 5 | Unknown |
| 6 | Voided trip |
| 99 | Not recorded |

### `dim_location` — Ubicaciones

Dimensión conformada que centraliza y unifica los identificadores de zonas de origen (`PULocationID`) y destino (`DOLocationID`) en una sola tabla de referencia.



## Evidencia de Ejecución

La carpeta `screenshots/` contiene 15 capturas de pantalla que documentan:

- El progreso de carga de los datos en Mage.ai (incluyendo el trigger automático entre pipelines).
- La correcta creación y contenido de cada tabla dimensional y de hechos, visualizadas tanto desde Mage.ai como desde pgAdmin 4.
- El conteo total de registros cargados en la base de datos (`cantidad_datos_pgadmin.png`).



## Análisis Exploratorio (Notebook)

El archivo `notebooks/pruebas_lab2.ipynb` documenta el trabajo de exploración y validación previo al diseño de las pipelines:

- Comparación de esquemas entre años (detección del campo `cbd_congestion_fee` introducido en 2025).
- Análisis de valores nulos por columna y por año.
- Identificación de anomalías de calidad de datos (años fuera de rango, distancias negativas).
- Estandarización de nombres de columnas a minúsculas.

Este análisis fue la base para las decisiones de diseño implementadas en los bloques de transformación.
