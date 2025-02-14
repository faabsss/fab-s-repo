# **Creación de una vista materializada para métricas clave de solicitudes de crédito**

3.1. Almacenar métricas clave de solicitudes de crédito como: monto promedio, plazo promedio y tasa de interés promedio por estado.
```sql
CREATE MATERIALIZED VIEW vista_metricas_credito AS
SELECT evaluaciones_riesgo.estado_creditos,
       COUNT(*) AS total_solicitudes,
	   ROUND(AVG(solicitudes_credito.monto_solicitado),2) AS monto_promedio,
	   ROUND(AVG(solicitudes_credito.plazo_meses),2) AS plazo_promedio,
	   ROUND(AVG(solicitudes_credito.tasa_interes),2) AS tasa_interés_promedio
FROM evaluaciones_riesgo
JOIN solicitudes_credito ON evaluaciones_riesgo.id_solicitud = solicitudes_credito.id_solicitud
GROUP BY evaluaciones_riesgo.estado_creditos

--> Para actualizar vista materializada
REFRESH MATERIALIZED VIEW vista_metricas_credito;
```
- Test de vista materializada
```sql
SELECT * 
FROM vista_metricas_credito
```
| estados_creditos | total_solicitudes | monto_promedio | plazo_promedio | tasa_interés_promedio |
|------------------|-------------------|----------------|----------------|-----------------------|
| Rechazado | 34 | 15605.37 | 33.88 | 9.71 |
| Aprobado | 124 | 15787.19 | 36.97 | 9.59 |
| Pendiente | 42 | 15521.18 | 37.14 | 9.42 |
