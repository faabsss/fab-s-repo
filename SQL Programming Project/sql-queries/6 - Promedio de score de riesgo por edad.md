# **Promedio de score de riesgo por edad**

**6.1 Determinar la relación entre el score de riesgo y edad del cliente**

```sql
SELECT DISTINCT ON (DATE_TRUNC('year', AGE(clientes.fecha_nacimiento))) 
       DATE_TRUNC('year', AGE(clientes.fecha_nacimiento)) AS edad, 
       COUNT(DISTINCT clientes.id_cliente) AS total_clientes, 
       ROUND(AVG(evaluaciones_riesgo.score_riesgo), 2) AS promedio_score
FROM clientes
JOIN solicitudes_credito ON clientes.id_cliente = solicitudes_credito.id_cliente
JOIN evaluaciones_riesgo ON solicitudes_credito.id_solicitud = evaluaciones_riesgo.id_solicitud
GROUP BY DATE_TRUNC('year', AGE(clientes.fecha_nacimiento))
ORDER BY DATE_TRUNC('year', AGE(clientes.fecha_nacimiento))
```
| edad | total_clientes | promedio_score |
|------|----------------|----------------|
| 24 years | 6 | 703.00 |
| 25 years | 4 | 547.75 |
| 26 years | 7 | 618.57 |
| 27 years | 8 | 689.25 |
| 28 years | 3 | 556.67 |
| 29 years | 6 | 580.83 |
| 30 years | 4 | 677.25 |
| 31 years | 4 | 647.25 |
| 32 years | 8 | 694.38 |
| 33 years | 6 | 646.33 |
| 34 years | 7 | 653.57 |
| 35 years | 5 | 552.80 |
| 36 years | 8 | 679.75 |
| 37 years | 6 | 615.00 |
| 38 years | 10 | 632.60 |
| 39 years | 9 | 680.56 |
| 40 years | 3 | 776.00 |
| 41 years | 6 | 671.67 |
| 42 years | 7 | 630.86 |
| 43 years | 9 | 640.00 |
| 44 years | 2 | 597.50 |
| 45 years | 12 | 656.08 |
| 46 years | 12 | 684.50 |
| 47 years | 6 | 627.83 |
| 48 years | 7 | 693.71 |
| 49 years | 6 | 649.00 |
| 50 years | 4 | 595.00 |
| 51 years | 2 | 730.50 |
| 52 years | 10 | 698.50 |
| 53 years | 7 | 738.86 |
| 54 years | 6 | 627.00 |
