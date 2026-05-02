# Glosario de negocio

## 1. Viaje válido

Registro de viaje que cumple las reglas mínimas de calidad: fecha de inicio menor que fecha de fin, distancia mayor que cero, tarifa positiva y campos críticos no nulos.

## 2. Hora pico

Franja horaria con mayor número de viajes registrados. En este proyecto se identifica a partir del ranking de viajes por franja horaria y día de la semana.

## 3. Borough

División administrativa de Nueva York. En el dataset de zonas se usa para agrupar ubicaciones como Manhattan, Queens, Brooklyn, Bronx, Staten Island, EWR y Unknown.

## 4. Zona de pickup

Zona donde inicia el viaje. Se obtiene al unir `PULocationID` de los viajes con `LocationID` del Taxi Zone Lookup.

## 5. Ingreso promedio por milla

Indicador de eficiencia económica que divide el ingreso total del viaje entre la distancia recorrida. Permite comparar zonas según rentabilidad relativa.
