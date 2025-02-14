-- 3. Creación de una vista materializada para métricas clave de solicitudes de crédito
-- 3.1. Almacenar métricas clave de solicitudes de crédito como: monto promedio, 
-- plazo promedio y tasa de interés promedio por estado.

CREATE MATERIALIZED VIEW vista_metricas_credito AS
SELECT evaluaciones_riesgo.estado_creditos,
       COUNT(*) AS total_solicitudes,
	   ROUND(AVG(solicitudes_credito.monto_solicitado),2) AS monto_promedio,
	   ROUND(AVG(solicitudes_credito.plazo_meses),2) AS plazo_promedio,
	   ROUND(AVG(solicitudes_credito.tasa_interes),2) AS tasa_interés_promedio
FROM evaluaciones_riesgo
JOIN solicitudes_credito ON evaluaciones_riesgo.id_solicitud = solicitudes_credito.id_solicitud
GROUP BY evaluaciones_riesgo.estado_creditos

-- Para actualizar vista materializada
REFRESH MATERIALIZED VIEW vista_metricas_credito;

--> TEST
-- SELECT * 
-- FROM vista_metricas_credito
       