# **SQL Programming Project**
![Python](https://img.shields.io/badge/Python-3.13-yellow)
![SQL](https://img.shields.io/badge/SQL-PostgreSQL-blue)
![Status](https://img.shields.io/badge/Status-InProgress-orange)


## **Descripción y objetivo de proyecto**

- Este documento contiene una serie de tareas estructuradas con el objetivo de practicar consultas en el lenguaje de programación SQL y desarrollar habilidades de análisis de datos.
  
- Tras la creación de una [database](https://github.com/faabsss/fab-s-repo/blob/66e418a6c6c14e1f053a3f8be3d3865f02106266/SQL%20Programming%20Project/sqlscript-data/DATA.md), se desarrollarán consultas que permitirán acceder a información para realizar:

**Análisis de riesgo de crédito**: Comprende de consultas que calculan el porcentaje de aprobaciones y rechazos. Además de, evaluar la relación entre el score de riesgo y la probabilidad de aprobación.

**Indicadores de cartera de crédito**: Se determinará tanto el promedio de la tasa de interés aprobada como su mediana según el nivel de riesgo. También:
- Se identificará la relación plazo de crédito promedio - tasa de interés promedio - nivel de riesgo.
- Se encontrará la relación entre nivel de riesgo, score de riesgo, monto solicitado promedio e ingreso promedio.
- Se observará la distribución de los montos solicitados por nivel de riesgo.
- Se identificará la correlación entre ingresos mensuales y alto nivel de riesgo de incumplimiento.

**Vistas materializadas**: Se crearán y actualizarán vistas con métricas clave, como distribución de montos aprobados y tasas de interés.

## **Archivos en las carpetas del proyecto**

> Las carpetas se enumerarán en orden de revisión, posterior a la lectura de este READ.ME:

1. pyscript-data: Esta carpeta contiene el archivo denominado 'Generador de datos para database de proyecto de análisis de datos en SQL.ipynb', el cual muestra cómo se crearon los datos que se muestran en las tablas que conforman la base de datos.
2. sqlscript-data: En esta carpeta se encuentra el archivo 'DATA.md', que explica y muestra el código de creación de tablas e inserción de información en el lenguaje de programación SQL.
3. sql-queries: Es la carpeta que contiene las consultas en SQL. Comprende de seis archivos.

## **Requisitos**
Para ejecutar el proyecto de manera local, asegúrate de instalar las siguientes dependencias:
- Python 3.x
- PostgreSQL, pgAdmin 4 8.x

