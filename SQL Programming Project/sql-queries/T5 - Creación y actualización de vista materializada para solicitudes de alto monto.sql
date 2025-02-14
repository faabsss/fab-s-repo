-- 5. Generación de una vista para solicitudes de alto monto (mayores al percentil 90%)
CREATE MATERIALIZED VIEW vista_solicitudes_alto_monto AS
SELECT *
FROM solicitudes_credito
WHERE monto_solicitado > (
  SELECT percentile_cont(0.90) WITHIN GROUP (ORDER BY monto_solicitado) 
  FROM solicitudes_credito
);

-- 9. Procedimiento para actualizar la vista de solicitudes de alto monto
CREATE OR REPLACE PROCEDURE actualizar_vista_solicitudes_alto_monto()
AS $$
BEGIN
    REFRESH MATERIALIZED VIEW vista_solicitudes_alto_monto;
END;
$$ LANGUAGE plpgsql;
