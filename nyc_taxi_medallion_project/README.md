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

## Decisiones técnicas

### Selección del mes de análisis

Para la prueba se trabajó únicamente con enero de 2023. Esta decisión permite mantener el alcance de la prueba, reducir tiempos de procesamiento y evitar consumo innecesario de recursos en el entorno de Azure Databricks.

### Uso de Delta Lake

Las tablas se almacenaron en formato Delta porque permite trabajar con datos de forma más confiable dentro de Databricks. Además, facilita la escritura y lectura de tablas, el manejo de cambios en el esquema y la integración con Unity Catalog para temas de gobierno y organización de los datos.

### Particionamiento en la capa Trusted

La tabla principal de la capa Trusted se particionó por pickup_date, ya que la fecha de recogida es un campo clave para los análisis de demanda. Esta partición ayuda a organizar mejor la información y puede mejorar las consultas cuando se filtra por periodos de tiempo.

### Criterios de limpieza y validación

En la capa Trusted se aplicaron reglas básicas para conservar únicamente viajes con condiciones razonables. Se excluyeron registros donde la fecha de inicio fuera posterior o igual a la fecha de finalización, viajes con distancia o tarifa no positiva, campos críticos nulos y valores extremos que podían afectar los indicadores.

Las reglas aplicadas fueron:

1. pickup_datetime < dropoff_datetime
2. trip_distance > 0
3. fare_amount > 0
4. Campos críticos no nulos
5. Duración del viaje entre 1 y 180 minutos
6. Distancia menor o igual a 100 millas
7. Valor total del viaje entre 0 y 1000 USD

Estas validaciones buscan retirar registros claramente inconsistentes, como viajes sin duración real, distancias imposibles, tarifas negativas o montos demasiado altos, sin modificar de manera excesiva el comportamiento natural del dataset.

### Manejo de valores atípicos

Para evitar que registros poco realistas afectaran los resultados, se definieron límites razonables sobre algunas variables del viaje. En este caso, se conservaron únicamente los registros que cumplieran con los siguientes rangos:

- Duración del viaje entre 1 y 180 minutos.
- Distancia recorrida mayor que 0 y menor o igual a 100 millas.
- Valor total cobrado entre 0 y 1000 USD.

Con estos criterios se buscó mantener viajes que pudieran ser reales y descartar casos evidentemente inconsistentes, como duraciones negativas, distancias demasiado altas o valores cobrados que no corresponden a un viaje normal.

### Definición de franjas horarias

Para analizar el comportamiento de la demanda durante el día, se dividieron las 24 horas en seis bloques de cuatro horas:

- 00-03
- 04-07
- 08-11
- 12-15
- 16-19
- 20-23

Esta agrupación permite observar de forma sencilla cómo cambia la demanda en la madrugada, la mañana, el mediodía, la tarde y la noche.

### Cálculo del ranking económico

El ranking de zonas se construyó a partir de indicadores relacionados con la eficiencia económica de los viajes. Para esto se calcularon métricas como el ingreso promedio por milla y la velocidad promedio del viaje.

- ingreso promedio por milla = promedio(total_amount / trip_distance)
- velocidad promedio = promedio(trip_distance / duración_en_horas)
- 
## Observabilidad

El notebook genera:

1. Logs con niveles `INFO`, `WARNING` y `ERROR`.
2. Tabla `refined.execution_report`.
3. Archivo JSON

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

## Limitaciones conocidas

- Solo se procesa enero 2023.
- El análisis se centra en zona de pickup.
- Las reglas de outliers son razonables para una prueba técnica, pero en producción deberían acordarse con negocio.
- El reporte de calidad por regla puede tener solapamientos: un mismo registro puede fallar más de una regla.
- En algunos entornos gratuitos puede que no tengas permisos para crear catálogos nuevos. Si pasa, usa el catálogo `workspace` y crea solo los schemas.
