## **Creación de datos para una database**

```python
import random
import pandas as pd
from datetime import datetime, timedelta
```

### **Creación de tabla 1: Clientes**

```python
def generar_fecha_nacimiento():
    inicio = datetime(1970, 1, 1)
    fin = datetime(2000, 12, 31)
    return inicio + timedelta(days=random.randint(0, (fin - inicio).days))

clientes_data = []
for cliente_id in range(1, 201):  # 200 clientes
    sexo = random.choice(['M', 'F'])
    fecha_nacimiento = generar_fecha_nacimiento().strftime('%Y-%m-%d')
    ingreso_mensual = round(random.uniform(1500, 10000), 2)  # Ingresos entre 1,500 y 10,000

    # Cada registro: (ID_Cliente, Sexo, Fecha_Nacimiento, Ingreso)
    clientes_data.append((cliente_id, sexo, fecha_nacimiento, ingreso_mensual))
```
### **Creación de tabla 2: Solicitudes de Crédito**

```python
solicitudes_data = []
for cliente_id, _, _, ingreso in clientes_data:
    monto_maximo = ingreso * 5  # El cliente puede solicitar hasta 5 veces su ingreso
    monto_solicitado = round(random.uniform(1000, min(monto_maximo, 50000)), 2)
    plazo_meses = random.choice([12, 24, 36, 48, 60])
    # La tasa se ajusta: menor ingreso → tasa mayor; se resta un valor proporcional al ingreso
    tasa_interes = round(random.uniform(5.0, 20.0) - (ingreso / 5000) * 3, 2)
    tasa_interes = max(3.5, tasa_interes)  # Mínimo 3.5%

    # Cada registro: (ID_Cliente, Monto_Solicitado, Plazo_Meses, Tasa_Interes)
    solicitudes_data.append((cliente_id, monto_solicitado, plazo_meses, tasa_interes))
```

### **Creación de tabla 3: Evaluaciones de Riesgo**

```python
evaluaciones_data = []
estados_solicitud = []  # Almacenará (ID_Solicitud, Estado)
for idx, (id_cliente, monto, plazo, tasa) in enumerate(solicitudes_data, start=1):
    # Buscar ingreso del cliente (en clientes_data, ingreso está en posición 3)
    ingreso_cliente = [c[3] for c in clientes_data if c[0] == id_cliente][0]
    # Calcular score en función del ingreso:
    # El score se escala entre 300 y 900: mayor ingreso → score más alto
    score_riesgo = min(900, max(300, int((ingreso_cliente / 10000) * 600 + 300)))
    if score_riesgo >= 750:
        nivel_riesgo = 'Bajo'
    elif score_riesgo >= 500:
        nivel_riesgo = 'Medio'
    else:
        nivel_riesgo = 'Alto'
    comentarios = f"Evaluación de riesgo: {nivel_riesgo}."
    # Cada registro: (ID_Solicitud, Score_Riesgo, Nivel_Riesgo, Comentarios)


    # Determinar estado de la solicitud basado en el nivel de riesgo
    if nivel_riesgo == 'Bajo':
        estado = 'Aprobado'
    elif nivel_riesgo == 'Medio':
        estado = random.choices(['Aprobado', 'Pendiente'], weights=[0.6, 0.4])[0]
    else:
        estado = 'Rechazado'
    estados_solicitud.append((idx, estado))
    evaluaciones_data.append((idx, score_riesgo, nivel_riesgo, estado, comentarios))
```
### **Creación de tabla 4: Pagos**

```python
pagos_data = []
for id_solicitud, estado in estados_solicitud:
    if estado == 'Aprobado':
        num_pagos = random.randint(1, 12)  # Entre 1 y 12 pagos registrados
        for _ in range(num_pagos):
            monto_pagado = round(random.uniform(100, 2000), 2)
            metodo_pago = random.choice(['Transferencia', 'Tarjeta', 'Efectivo'])

            # Cada registro: (ID_Solicitud, Monto_Pagado, Método_Pago)
            pagos_data.append((id_solicitud, monto_pagado, metodo_pago))
```

### **Creación de tabla 5: Historial crediticio**

```python
historial_crediticio_data = []
for cliente_id in range(1, 201):
    cantidad_prestamos = random.randint(0, 5)  # Entre 0 y 5 préstamos previos
    monto_total = round(random.uniform(1000, 100000), 2) if cantidad_prestamos > 0 else 0
    historial_pagos = random.choices(['Bueno', 'Regular', 'Malo'], weights=[0.6, 0.3, 0.1])[0] if cantidad_prestamos > 0 else 'Bueno'

    # Cada registro: (ID_Cliente, Monto_Total, Cantidad_Prestamos, Historial_Pagos)
    historial_crediticio_data.append((cliente_id, monto_total, cantidad_prestamos, historial_pagos))
```

## **Descarga de resultados**

```python
# Mostrar resultados
df_clientes = pd.DataFrame(clientes_data, columns=['ID_Cliente', 'Sexo', 'Fecha_Nacimiento', 'Ingreso'])
print("Tabla 1: Clientes")
print(df_clientes.head(200))
print("\n" + "-"*50 + "\n")

df_solicitudes_credito = pd.DataFrame(solicitudes_data, columns=['ID_Cliente', 'Monto_Solicitado', 'Plazo_Meses', 'Tasa_Interes'])
print("\nTabla 2: Solicitudes de crédito")
print(df_solicitudes_credito.head(200))
print("\n" + "-"*50 + "\n")

df_evaluaciones_riesgo = pd.DataFrame(evaluaciones_data, columns=['ID_Solicitud', 'Score_Riesgo', 'Nivel_Riesgo', 'Estado_Creditos', 'Comentarios'])
print("\nTabla 3: Evaluaciones de riesgo")
print(df_evaluaciones_riesgo.head(200))
print("\n" + "-"*50 + "\n")

df_pagos = pd.DataFrame(pagos_data, columns=['ID_Solicitud', 'Monto_Pagado', 'Método_Pago'])
print("\nTabla 4: Pagos")
print(df_pagos.head(200))
print("\n" + "-"*50 + "\n")

df_historial_crediticio = pd.DataFrame(historial_crediticio_data, columns=['ID_Cliente', 'Monto_Total', 'Cantidad_Prestamos', 'Historial_Pagos'])
print("\nTabla 5: Historial crediticio")
print(df_historial_crediticio.head(200))
print("\n" + "-"*50 + "\n")

# Guardar tablas en un archivo CSV
def save_dataframes():
    df_clientes.to_csv('clientes.csv', index=False)
    df_solicitudes_credito.to_csv('solicitudes_credito.csv', index=False)
    df_evaluaciones_riesgo.to_csv('evaluaciones_riesgo.csv', index=False)
    df_pagos.to_csv('pagos.csv', index=False)
    df_historial_crediticio.to_csv('historial_crediticio.csv', index=False)
    print("Se guardaron las tablas en archivos CSV.")

save_dataframes()

# Descarga de archivos en Colab
from google.colab import files
files.download('clientes.csv')
files.download('solicitudes_credito.csv')
files.download('evaluaciones_riesgo.csv')
files.download('pagos.csv')
files.download('historial_crediticio.csv')
```



