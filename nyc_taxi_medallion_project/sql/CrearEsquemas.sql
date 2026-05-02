-- 00_create_catalog_schemas.sql

CREATE CATALOG IF NOT EXISTS nyc_taxi_sebastian
COMMENT 'Catálogo para pipeline ETL Medallion de NYC Yellow Taxi';

USE CATALOG nyc_taxi_sebastian;

CREATE SCHEMA IF NOT EXISTS raw
COMMENT 'Capa Raw: datos ingeridos casi sin transformación';

CREATE SCHEMA IF NOT EXISTS trusted
COMMENT 'Capa Trusted: datos limpiados, validados y enriquecidos';

CREATE SCHEMA IF NOT EXISTS refined
COMMENT 'Capa Refined: KPIs, reportes y productos analíticos';
