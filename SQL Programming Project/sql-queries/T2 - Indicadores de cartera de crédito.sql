-- 2. Indicadores de cartera de crédito

-- 2.1. Determinar la tasa de interés promedio aprobada por nivel de riesgo
SELECT evaluaciones_riesgo.nivel_riesgo,
       ROUND(AVG(solicitudes_credito.tasa_interes),2) AS tasa_interes_promedio
FROM evaluaciones_riesgo
JOIN solicitudes_credito ON evaluaciones_riesgo.id_solicitud = solicitudes_credito.id_solicitud
WHERE evaluaciones_riesgo.estado_creditos = 'Aprobado'
GROUP BY evaluaciones_riesgo.nivel_riesgo
ORDER BY evaluaciones_riesgo.nivel_riesgo

--- 2.1.1. Relación mediana de la tasa de interés aprobada - nivel de riesgo
SELECT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY solicitudes_credito.tasa_interes) AS mediana_tasa_interes,
       evaluaciones_riesgo.nivel_riesgo
FROM evaluaciones_riesgo
JOIN solicitudes_credito ON evaluaciones_riesgo.id_solicitud = solicitudes_credito.id_solicitud
WHERE evaluaciones_riesgo.estado_creditos = 'Aprobado'
GROUP BY evaluaciones_riesgo.nivel_riesgo
ORDER BY evaluaciones_riesgo.nivel_riesgo


--- 2.2. Relación plazo de crédito promedio - tasa de interés promedio - nivel de riesgo
SELECT evaluaciones_riesgo.nivel_riesgo, 
       ROUND(AVG(solicitudes_credito.monto_solicitado), 2) AS monto_solicitado_promedio,
	   ROUND(AVG(solicitudes_credito.plazo_meses), 2) AS plazo_promedio,
       ROUND(AVG(solicitudes_credito.tasa_interes), 2) AS tasa_interes_promedio
FROM evaluaciones_riesgo 
JOIN solicitudes_credito ON evaluaciones_riesgo.id_solicitud = solicitudes_credito.id_solicitud
GROUP BY evaluaciones_riesgo.nivel_riesgo
ORDER BY evaluaciones_riesgo.nivel_riesgo;

--- 2.2.1. Relación entre nivel de riesgo, score de riesgo, monto solicitado promedio e ingreso promedio
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

--- 2.2.2. Distribución de los montos solicitados por nivel de riesgo
SELECT evaluaciones_riesgo.nivel_riesgo,
       ROUND(AVG(solicitudes_credito.monto_solicitado),2) AS monto_solicitado_promedio,
       MAX(solicitudes_credito.monto_solicitado) AS monto_solicitado_max,
       MIN(solicitudes_credito.monto_solicitado) AS monto_solicitado_min
FROM evaluaciones_riesgo
JOIN solicitudes_credito ON evaluaciones_riesgo.id_solicitud = solicitudes_credito.id_solicitud
GROUP BY evaluaciones_riesgo.nivel_riesgo
ORDER BY evaluaciones_riesgo.nivel_riesgo


-- 2.3. Identificar ingresos de clientes con alto riesgo de incumplimiento
SELECT clientes.ingreso_mensual,
	   evaluaciones_riesgo.score_riesgo,
	   evaluaciones_riesgo.nivel_riesgo
FROM clientes
JOIN solicitudes_credito ON clientes.id_cliente = solicitudes_credito.id_cliente
JOIN evaluaciones_riesgo ON solicitudes_credito.id_solicitud = evaluaciones_riesgo.id_solicitud
WHERE evaluaciones_riesgo.nivel_riesgo = 'Alto'
ORDER BY evaluaciones_riesgo.score_riesgo ASC 


