# **Creación y actualización de vista materializada para solicitudes de alto monto**
**5.1 Generación de una vista para solicitudes de alto monto (mayores al percentil 90%)**

```sql
CREATE MATERIALIZED VIEW vista_solicitudes_alto_monto AS
SELECT *
FROM solicitudes_credito
WHERE monto_solicitado > (
  SELECT percentile_cont(0.90) WITHIN GROUP (ORDER BY monto_solicitado) 
  FROM solicitudes_credito
);
```
- Test de vista materializada
  
```sql
SELECT *
FROM vista_solicitudes_alto_monto
```

| id_solicitud | id_cliente | monto_solicitado | plazo_meses | tasa_interes |
|--------------|------------|------------------|-------------|--------------|
| 1	| 1	| 31860.39 | 24	| 3.99 |
| 8	| 8	| 38489.20	| 36	| 6.71 |
| 17 | 17	| 33843.66 | 12	| 9.33 |
| 31 | 31	| 37892.66	| 36	| 9.57 |
| 51 | 51	| 31663.39	| 36	| 7.21 |
| 65 | 65	| 29699.10	| 48	| 9.75 |
| 73 | 73	| 30849.47	| 60	| 9.03 |
| 91 | 91	| 33867.82	| 12	| 10.80 |
| 94 | 94	| 31510.54	| 60	| 10.68 |
| 95 | 95	| 29864.84	| 12	| 7.12 |
| 101	| 101	| 37771.08	| 48	| 7.95 | 
| 104	| 104	| 30688.02	| 24	| 10.27 |
| 115	| 115	| 35301.33	| 60	| 4.04 |
| 132	| 132	| 33221.69	| 24	| 5.45 |
| 137	| 137	| 39485.67	| 48	| 13.50 |
| 154	| 154	| 38895.58	| 36	| 13.53 |
| 176	| 176	| 43860.57	| 60	| 5.35 |
| 179	| 179	| 30126.43	| 48	| 3.50 |
| 180	| 180	| 31494.97	| 60	| 5.79 |
| 193	| 193	| 37775.12	| 12	| 13.69 |

**5.2 Procedimiento para actualizar la vista de solicitudes de alto monto**

```sql
CREATE OR REPLACE PROCEDURE actualizar_vista_solicitudes_alto_monto()
AS $$
BEGIN
    REFRESH MATERIALIZED VIEW vista_solicitudes_alto_monto;
END;
$$ LANGUAGE plpgsql;
```

- Test de procedimiento almacenado
```sql
CALL actualizar_vista_solicitudes_alto_monto();
```
