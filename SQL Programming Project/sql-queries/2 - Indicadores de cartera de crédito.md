# **Indicadores de cartera de crédito**

2.1. Determinar la tasa de interés promedio aprobada por nivel de riesgo
```sql
SELECT evaluaciones_riesgo.nivel_riesgo,
       ROUND(AVG(solicitudes_credito.tasa_interes),2) AS tasa_interes_promedio
FROM evaluaciones_riesgo
JOIN solicitudes_credito ON evaluaciones_riesgo.id_solicitud = solicitudes_credito.id_solicitud
WHERE evaluaciones_riesgo.estado_creditos = 'Aprobado'
GROUP BY evaluaciones_riesgo.nivel_riesgo
ORDER BY evaluaciones_riesgo.nivel_riesgo
```
| nivel_riesgo | tasa_interes_promedio |
|--------------|-----------------------|
| Alto | 10.93 |
| Bajo | 8.35 |
| Medio | 9.99 |

2.1.1. Relación mediana de la tasa de interés aprobada - nivel de riesgo
```sql
SELECT evaluaciones_riesgo.nivel_riesgo,
       PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY solicitudes_credito.tasa_interes) AS mediana_tasa_interes
FROM evaluaciones_riesgo
JOIN solicitudes_credito ON evaluaciones_riesgo.id_solicitud = solicitudes_credito.id_solicitud
WHERE evaluaciones_riesgo.estado_creditos = 'Aprobado'
GROUP BY evaluaciones_riesgo.nivel_riesgo
ORDER BY evaluaciones_riesgo.nivel_riesgo
```
| nivel_riesgo | mediana_tasa_interes |
|--------------|----------------------|
| Alto | 13.31 |
| Bajo | 7.925000000000001 |
| Medio | 10.63 |

- Debido a los valores extremos que considera el promedio, se puede observar las diferencias porcentuales con respecto a la mediana de las tasas de interés aprobadas, según el nivel de riesgo.
- La mediana refleja valores más exactos y sostiene la lógica que se muestra al calcular el promedio. Es decir, si el nivel de riesgo - de incumplimiento - de un cliente es alto, entonces accederá a un crédito con una alta tasa de interés. Caso contrario, el cliente obtendrá préstamos a tasas más favorables.


2.2. Relación entre el plazo de crédito, monto solicitado y tasa de interés promedio, según el nivel de riesgo
```sql
SELECT evaluaciones_riesgo.nivel_riesgo, 
       ROUND(AVG(solicitudes_credito.monto_solicitado), 2) AS monto_solicitado_promedio,
	   ROUND(AVG(solicitudes_credito.plazo_meses), 2) AS plazo_promedio,
       ROUND(AVG(solicitudes_credito.tasa_interes), 2) AS tasa_interes_promedio
FROM evaluaciones_riesgo 
JOIN solicitudes_credito ON evaluaciones_riesgo.id_solicitud = solicitudes_credito.id_solicitud
GROUP BY evaluaciones_riesgo.nivel_riesgo
ORDER BY evaluaciones_riesgo.nivel_riesgo;
```

| nivel_riesgo | monto_solicitado_promedio | plazo_promedio | tasa_interes_promedio |
|--------------|---------------------------|----------------|-----------------------|
| Alto | 6415.48 | 32.47 | 11.30 | 
| Bajo | 19999.82 | 36.79 | 7.98 |
| Medio | 16209.21 | 37.60 | 9.94 |


2.2.1. Relación entre nivel de riesgo, score de riesgo, monto solicitado promedio e ingreso promedio
```sql
SELECT evaluaciones_riesgo.nivel_riesgo,
       ROUND(AVG(evaluaciones_riesgo.score_riesgo), 2) AS promedio_score,
       ROUND(AVG(clientes.ingreso_mensual), 2) AS ingreso_mensual_promedio,
       ROUND(AVG(solicitudes_credito.monto_solicitado), 2) AS monto_promedio
FROM clientes
JOIN solicitudes_credito 
    ON clientes.id_cliente = solicitudes_credito.id_cliente
JOIN evaluaciones_riesgo 
    ON solicitudes_credito.id_solicitud = evaluaciones_riesgo.id_solicitud
GROUP BY evaluaciones_riesgo.nivel_riesgo
ORDER BY promedio_score;
```

| nivel_riesgo | promedio_score | ingreso_mensual_promedio | monto_promedio |
|--------------|----------------|--------------------------|----------------|
| Alto | 442.59 | 2384.12 | 6415.48 |
| Medio | 622.85 | 5388.62 | 16209.21 |
| Bajo | 831.20	| 8861.79 | 19999.82 |

2.2.2. Distribución de los montos solicitados por nivel de riesgo
```sql
SELECT evaluaciones_riesgo.nivel_riesgo,
       ROUND(AVG(solicitudes_credito.monto_solicitado),2) AS monto_solicitado_promedio,
       MAX(solicitudes_credito.monto_solicitado) AS monto_solicitado_max,
       MIN(solicitudes_credito.monto_solicitado) AS monto_solicitado_min
FROM evaluaciones_riesgo
JOIN solicitudes_credito ON evaluaciones_riesgo.id_solicitud = solicitudes_credito.id_solicitud
GROUP BY evaluaciones_riesgo.nivel_riesgo
ORDER BY evaluaciones_riesgo.nivel_riesgo
```

| nivel_riesgo | monto_solicitado_promedio | monto_solicitado_max | monto_solicitado_min |
|--------------|---------------------------|----------------------|----------------------|
| Alto | 6415.48 | 15862.10 | 1655.60 |
| Bajo | 19999.82 | 43860.57 | 1150.17 |
| Medio | 16209.21 | 33843.66 | 1018.77 |


2.3. Identificar ingresos de clientes con alto riesgo de incumplimiento
```sql
SELECT clientes.ingreso_mensual,
	   evaluaciones_riesgo.score_riesgo,
	   evaluaciones_riesgo.nivel_riesgo
FROM clientes
JOIN solicitudes_credito ON clientes.id_cliente = solicitudes_credito.id_cliente
JOIN evaluaciones_riesgo ON solicitudes_credito.id_solicitud = evaluaciones_riesgo.id_solicitud
WHERE evaluaciones_riesgo.nivel_riesgo = 'Alto'
ORDER BY evaluaciones_riesgo.score_riesgo ASC
``` 
| ingreso_mensual | score_riesgo | nivel_riesgo |
|-----------------|--------------|--------------|
| 1500 | 390 | Alto |
| 1593 | 395 | Alto |
| 1596 | 395 | Alto |
| 1614 | 396 | Alto |
| 1617 | 397 | Alto |
| 1689 | 401 | Alto |
| 1754 | 405 | Alto |
| 1784 | 407 | Alto |
| 1802 | 408 | Alto |
| 1840 | 410 | Alto |
| 1943 | 416 | Alto |
| 1988 | 419 | Alto |
| 1989 | 419 | Alto |
| 2018 | 421 | Alto | 
| 2049 | 422 | Alto |
| 2157 | 429 | Alto |
| 2243 | 434 | Alto |
| 2382 | 442 | Alto |
| 2500 | 450 | Alto |
| 2558 | 453 | Alto |
| 2642 | 458 | Alto | 
| 2672 | 460 | Alto |
| 2731 | 463 | Alto |
| 2859 | 471 | Alto |
| 2913 | 474 | Alto |
| 2953 | 477 | Alto |
| 3085 | 485 | Alto |
| 3091 | 485 | Alto |
| 3122 | 487 | Alto | 
| 3188 | 491 | Alto |
| 3262 | 495 | Alto |
| 3300 | 497 | Alto |
| 3294 | 497 | Alto |
| 3332 | 499 | Alto |

