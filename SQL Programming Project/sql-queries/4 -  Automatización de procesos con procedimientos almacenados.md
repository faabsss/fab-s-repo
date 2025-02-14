# **Automatización de procesos con procedimientos almacenados**
**4.1. Procedimiento almacenado para actualizar la vista materializada**

DOCUMENTACIÓN:
- CREATE OR REPLACE PROCEDURE: Crea un procedimiento almacenado o lo reemplaza si ya existe.
- actualizar_vista_metricas: Nombre del procedimiento.
- Los paréntesis () indican que el procedimiento no recibe parámetros.

```sql
CREATE OR REPLACE PROCEDURE actualizar_vista_metricas()
AS $$
BEGIN
    REFRESH MATERIALIZED VIEW vista_metricas_credito;
END;
$$ LANGUAGE plpgsql;
```

4.2. Procedimiento almacenado para asignar nivel de riesgo a nuevas solicitudes

DOCUMENTACIÓN: 
- UPDATE evaluaciones_riesgo: Modifica la tabla evaluaciones_riesgo.
- SET nivel_riesgo = CASE: Asigna un nivel de riesgo según el score_riesgo.
- Condiciones:
   - score_riesgo >= 750 → Nivel de riesgo "Bajo".
   - score_riesgo BETWEEN 500 AND 749 → Nivel de riesgo "Medio".
   - ELSE 'Alto' → Si el score_riesgo es menor a 500, se asigna "Alto".

```sql
CREATE OR REPLACE PROCEDURE asignar_nivel_riesgo()
AS $$
BEGIN
    UPDATE evaluaciones_riesgo 
    SET nivel_riesgo = CASE 
        WHEN score_riesgo >= 750 THEN 'Bajo'
        WHEN score_riesgo BETWEEN 500 AND 749 THEN 'Medio'
        ELSE 'Alto'
    END;
END;
$$ LANGUAGE plpgsql;
```

- Test de procedimiento almacenado
```sql
CALL asignar_nivel_riesgo();
```
