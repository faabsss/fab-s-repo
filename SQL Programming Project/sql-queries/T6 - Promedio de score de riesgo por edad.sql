--- 6. Promedio de score de riesgo por edad
SELECT DISTINCT ON (DATE_TRUNC('year', AGE(clientes.fecha_nacimiento))) 
       DATE_TRUNC('year', AGE(clientes.fecha_nacimiento)) AS edad, 
       COUNT(DISTINCT clientes.id_cliente) AS total_clientes, 
       ROUND(AVG(evaluaciones_riesgo.score_riesgo), 2) AS promedio_score
FROM clientes
JOIN solicitudes_credito ON clientes.id_cliente = solicitudes_credito.id_cliente
JOIN evaluaciones_riesgo ON solicitudes_credito.id_solicitud = evaluaciones_riesgo.id_solicitud
GROUP BY DATE_TRUNC('year', AGE(clientes.fecha_nacimiento))
ORDER BY DATE_TRUNC('year', AGE(clientes.fecha_nacimiento))