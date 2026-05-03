# NYC Yellow Taxi

## Resumen de lo realizado
Se desarrolló un pipeline ETL en Azure Databricks para trabajar con los datos públicos de NYC Yellow Taxi Trips correspondientes a enero de 2023. Para complementar la información de los viajes, se utilizó el archivo Taxi Zone Lookup, el cual permitió asociar cada zona de recogida con su borough y nombre de zona.

El flujo se organizó siguiendo una arquitectura Medallion con tres capas Raw, Trusted y Refined. En Raw se cargaron los datos originales con cambios mínimos; en Trusted se aplicaron validaciones, limpieza de registros, control de valores atípicos y enriquecimiento de la información; y en Refined se construyeron las tablas finales para análisis, incluyendo indicadores de demanda temporal, rentabilidad por zona, calidad de datos y el reporte general de ejecución.

También se configuró la estructura de gobierno en Unity Catalog mediante el catálogo nyc_taxi_sebastian y los schemas raw, trusted y refined. Para el manejo de archivos fuente y reportes generados por el proceso, se usó un Unity Catalog Volume, evitando depender de rutas locales o de DBFS/FileStore.

Como parte de la documentación, se incluyeron los elementos críticos de datos en docs/cdes.md, un glosario de negocio en docs/glosario.md y la descripción del linaje en docs/lineage.md. Además, se agregaron capturas de pantalla como evidencia de la creación del catálogo, las capas, las tablas generadas, los KPIs, el reporte de calidad, el reporte final y la vista de linaje.

Tablas:

### Raw

- `raw.yellow_taxi_trips`
- `raw.taxi_zones`

### Trusted

- `trusted.yellow_taxi_trips_enriched`

### Refined

- `refined.kpi_temporal_demand`
- `refined.kpi_temporal_peaks`
- `refined.kpi_zone_economic_efficiency`
- `refined.kpi_top10_profitable_zones`
- `refined.kpi_borough_economic_efficiency`
- `refined.data_quality_report`
- `refined.kpi_data_quality_impact`
- `refined.execution_report`

---

## Paso a paso para ejecutar en Databricks

### 1. Crear o abrir workspace

Puedes usar Azure Databricks o Databricks Free/Community Edition.

### 2. Crear cluster
Crea un cluster con Runtime que soporte Delta y Unity Catalog.

El que se uso para el trabajo (Recomendado):

- Databricks Runtime 14.x.
- Cluster single node.

### 3. Importar el notebook

Importa el archivo:

```text
notebooks/NB_Carga_nyc_taxi.ipynb
```

En Databricks:

1. Workspace.
2. Import.
3. File.
4. Selecciona el notebook `.ipynb`.

### 4. Ejecutar notebook

Validación de datos.

---

## Decisiones técnicas

### Por qué enero 2023

Se usa un solo mes para cumplir el alcance de la prueba y evitar costos altos en ambiente gratuito.

### Por qué Delta Lake

Delta permite tablas transaccionales, relectura confiable, manejo de schema y gobierno con Unity Catalog.

### Por qué particionar por fecha de pickup en Trusted

La tabla Trusted se particiona por `pickup_date` porque los análisis temporales y filtros por fecha suelen ser frecuentes.

### Reglas de limpieza aplicadas

Se descartan registros que incumplan estas reglas:

1. `pickup_datetime < dropoff_datetime`
2. `trip_distance > 0`
3. `fare_amount > 0`
4. Campos críticos no nulos.
5. Duración entre 1 y 180 minutos.
6. Distancia menor o igual a 100 millas.
7. Total cobrado entre 0 y 1000 USD.

Estas reglas buscan eliminar viajes imposibles, datos incompletos y outliers extremos sin hacer una limpieza excesiva.

### Outliers

Criterio aplicado:

- Duración: 1 a 180 minutos.
- Distancia: 0 a 100 millas.
- Total: 0 a 1000 USD.

La razón es conservar viajes reales largos, pero eliminar errores evidentes como duraciones negativas, distancias exageradas o importes imposibles para un viaje urbano.

### Franja horaria

Se usan 6 franjas de 4 horas:

- 00-03
- 04-07
- 08-11
- 12-15
- 16-19
- 20-23

Esto permite ver patrones de madrugada, mañana, mediodía, tarde y noche.

### Ranking económico

El ranking de zonas se calcula con:

```text
ingreso promedio por milla = promedio(total_amount / trip_distance)
velocidad promedio = promedio(trip_distance / duración_horas)
```

Se aplica un mínimo de 100 viajes por zona para evitar que zonas con muy pocos registros distorsionen el ranking.

---

## Observabilidad

El notebook genera:

1. Logs con niveles `INFO`, `WARNING` y `ERROR`.
2. Tabla `refined.execution_report`.
3. Archivo JSON en DBFS:

```text
dbfs:/FileStore/nyc_taxi_etl/reports/
```

El reporte contiene:

- Total procesado.
- Registros descartados.
- Tiempo por etapa.
- Tablas generadas.
- KPIs principales.

---

## Manejo de errores y reintentos

Cada etapa del pipeline se ejecuta con función `run_with_retry`.

Por defecto:

- 2 reintentos.
- Espera incremental entre intentos.
- Log de error por etapa.
- Si falla definitivamente, el notebook termina con excepción controlada.

---

## Validaciones finales sugeridas

Después de ejecutar, valida:

```sql
SELECT COUNT(*) FROM nyc_taxi_sebastian.raw.yellow_taxi_trips;
SELECT COUNT(*) FROM nyc_taxi_sebastian.trusted.yellow_taxi_trips_enriched;
SELECT * FROM nyc_taxi_sebastian.refined.data_quality_report;
SELECT * FROM nyc_taxi_sebastian.refined.kpi_temporal_peaks;
SELECT * FROM nyc_taxi_sebastian.refined.kpi_top10_profitable_zones;
SELECT * FROM nyc_taxi_sebastian.refined.execution_report;
```

---

## Limitaciones conocidas

- Solo se procesa enero 2023.
- El análisis se centra en zona de pickup.
- Las reglas de outliers son razonables para una prueba técnica, pero en producción deberían acordarse con negocio.
- El reporte de calidad por regla puede tener solapamientos: un mismo registro puede fallar más de una regla.
- En algunos entornos gratuitos puede que no tengas permisos para crear catálogos nuevos. Si pasa, usa el catálogo `workspace` y crea solo los schemas.
