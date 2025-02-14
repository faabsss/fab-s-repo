# **Análisis de riesgo de crédito**

1.1. Determinar el porcentaje de solicitudes aprobadas y rechazadas.
```sql
SELECT estado_creditos,
  COUNT(*) AS total_solicitudes,
  ROUND(100.0 * COUNT(*)/SUM(COUNT(*)) OVER(), 2) AS porcentaje
FROM evaluaciones_riesgo
GROUP BY estado_creditos

-- Otra manera
SELECT 
  ROUND(100.0 * SUM(CASE WHEN estado_creditos = 'Aprobado' THEN 1 ELSE 0 END) / COUNT(*), 2) AS porcentaje_aprobacion,
  ROUND(100.0 * SUM(CASE WHEN estado_creditos = 'Rechazado' THEN 1 ELSE 0 END) / COUNT(*), 2) AS porcentaje_rechazo
FROM evaluaciones_riesgo
```

| estado_creditos |  total_solicitudes | porcentaje |
|-----------------|--------------------|------------|
| Rechazado | 34 | 17.00 |
|Aprobado | 124 | 62.00 |
|Pendiente | 42 | 21.00 |

- La entidad bancaria aprobó 124 solicitudes de crédito, dicha cifra representa el 62% del total de solicitudes percibidas.
- Por otro lado, 34 solicitudes de crédito fueron rechazadas, representando el 17% del total de solicitudes.
- Por último, existen 42 solicitudes de crédito que se encuentran pendientes de evaluación, siendo el 21% del total de solicitudes.

1.2. Encontrar la relación entre el nivel de riesgo y la probabilidad de aceptación
```sql
SELECT nivel_riesgo,
  COUNT(id_solicitud) AS total_solicitudes,
  SUM(CASE WHEN estado_creditos = 'Aprobado' THEN 1 ELSE 0 END) AS aprobadas,
  ROUND(100.0 * SUM(CASE WHEN estado_creditos = 'Aprobado' THEN 1 ELSE 0 END)/COUNT(id_solicitud), 2) AS tasa_aprobacion
FROM evaluaciones_riesgo
GROUP BY evaluaciones_riesgo.nivel_riesgo
ORDER BY evaluaciones_riesgo.nivel_riesgo;
```

| nivel_riesgo |  total_solicitudes | aprobadas | tasa_aprobacion |
|-----------------|--------------------|-----------|-----------------|
| Alto |	34 | 21	| 61.76 |
| Bajo | 61 |	42 | 68.85 |
| Medio |	105	| 61 | 58.10 |

- La entidad bancaria presenta un mayor alcance a clientes con niveles de riesgo catalogados medio y bajo, quienes tienen una tasa de aprobación superior al 50% del total de solicitudes. Por lo que, se podría inferir - por el momento - de que actualmente maneja una cartera de créditos diversificada.
- No obstante, se debe considerar que solo presenta 34 solicitudes de crédito de clientes de alto riesgo. Estas solicitudes muestran una alta tasa de aprobación (61.76%), la cual es superior a la tasa de créditos concedidos a clientes de riesgo medio.
- Posteriormente, se determinará qué otras variables pueden influir en el establecimiento del nivel de riesgo y en la probabilidad de aceptación.
