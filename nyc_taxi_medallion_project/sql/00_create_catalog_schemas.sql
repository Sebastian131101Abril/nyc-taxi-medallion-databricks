
-- Creación de estructura Unity Catalog para NYC Taxi
-- Catálogo principal del proyecto
CREATE CATALOG IF NOT EXISTS nyc_taxi_sebastian
COMMENT 'Catálogo para pipeline ETL de NYC Yellow Taxi';

USE CATALOG nyc_taxi_sebastian;

-- Schema Raw / Bronze
CREATE SCHEMA IF NOT EXISTS raw
COMMENT 'Capa Raw/Bronze: datos fuente ingeridos con transformación mínima';

-- Schema Trusted / Silver
CREATE SCHEMA IF NOT EXISTS trusted
COMMENT 'Capa Trusted/Silver: datos limpios, validados y enriquecidos';

-- Schema Refined / Gold
CREATE SCHEMA IF NOT EXISTS refined
COMMENT 'Capa Refined/Gold: KPIs, reportes y productos analíticos';

-- Volume para archivos fuente y reportes JSON
CREATE VOLUME IF NOT EXISTS raw.nyc_taxi_files
COMMENT 'Volume para almacenar archivos fuente del pipeline y reportes de ejecución';
