# Critical Data Elements - NYC Yellow Taxi

## 1. pickup_datetime

| Campo | Detalle |
|---|---|
| Nombre de negocio | Fecha y hora de inicio del viaje |
| Definición | Momento en que el pasajero inicia el viaje en taxi. |
| Regla de calidad | No debe ser nulo y debe ser menor que `dropoff_datetime`. |
| Tabla / columna | `trusted.yellow_taxi_trips_enriched.pickup_datetime` |
| Uso analítico | Permite analizar demanda por hora, franja horaria y día de la semana. |

---

## 2. trip_distance

| Campo | Detalle |
|---|---|
| Nombre de negocio | Distancia del viaje |
| Definición | Distancia recorrida durante el viaje, expresada en millas. |
| Regla de calidad | Debe ser mayor que 0 y menor o igual a 100 millas. |
| Tabla / columna | `trusted.yellow_taxi_trips_enriched.trip_distance` |
| Uso analítico | Permite calcular eficiencia económica por milla y velocidad promedio. |

---

## 3. total_amount

| Campo | Detalle |
|---|---|
| Nombre de negocio | Ingreso total del viaje |
| Definición | Valor total cobrado al pasajero, incluyendo tarifa, extras, impuestos, propinas y recargos. |
| Regla de calidad | No debe ser nulo y debe estar entre 0 y 1000 USD. |
| Tabla / columna | `trusted.yellow_taxi_trips_enriched.total_amount` |
| Uso analítico | Permite calcular ingresos, rentabilidad por zona e impacto económico de registros descartados. |
