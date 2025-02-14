-- 1. Análisis de riesgo de crédito

-- 1.1. Determinar el porcentaje de solicitudes aprobadas y rechazadas
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

-- La entidad bancaria aprobó 124 solicitudes de crédito, dicha cifra representa el 62% del total de solicitudes percibidas.
-- Por otro lado, 34 solicitudes de crédito fueron rechazadas, representando el 17% del total de solicitudes.
-- Por último, existen 42 solicitudes de crédito que se encuentran pendientes de evaluación, siendo el 21% del total de solicitudes.

-- 1.2. Encontrar la relación entre el nivel de riesgo y la probabilidad de aceptación
SELECT nivel_riesgo,
  COUNT(id_solicitud) AS total_solicitudes,
  SUM(CASE WHEN estado_creditos = 'Aprobado' THEN 1 ELSE 0 END) AS aprobadas,
  ROUND(100.0 * SUM(CASE WHEN estado_creditos = 'Aprobado' THEN 1 ELSE 0 END)/COUNT(id_solicitud), 2) AS tasa_aprobacion
FROM evaluaciones_riesgo
GROUP BY evaluaciones_riesgo.nivel_riesgo
ORDER BY evaluaciones_riesgo.nivel_riesgo;









