# **Construcción del Modelo de Heterocedasticidad Condicional Autorregresiva Generalizada**

Es un modelo econométrico que permite evaluar y modelar la volatilidad en series de tiempo financieras. Plantea que existe autocorrelación en la varianza de series temporales y; que esta no es constante en el tiempo. De manera que, reconoce que la volatilidad financiera no es uniforme y que los periodos de alta volatilidad tiende a generar clústeres.
La varianza depende tanto de errores pasados como de sus valores tomados en el pasado, puesto que los mercados no se comportan únicamente de manera aleatoria.

## **Especificación del modelo**

Orden del GARCH(p, q):
> - p: Número de términos autorregresivos de la varianza (GARCH).
> - q: Número de términos de los errores al cuadrado (ARCH).

## **Distribución de los errores:**

- Normal (Gaussiana).
- t-Student (para capturar colas pesadas).
- Distribución Generalizada de Errores (GED).
  
**Principales propiedades**
- No estacionariedad en la varianza.
- Estacionariedad en la media: La serie debe ser estacionaria en su componente de media. Caso contrario, se deben aplicar transformaciones como la diferenciación (para eliminar tendencias) o transformaciones log, Box-Cox para estabilizar la media.
- Ausencia de autocorrelación en la media: Si hay autocorrelación, primero se debe modelar la media con un proceso ARMA(p,q) mediante un modelo ARMA-GARCH
- Alpha debe ser positivo, así garantiza una varianza positiva.
- Los sucesos más recientes generan mayor efecto.
- La sumatoria de alpha y beta deben de permanecer entre 0 y 1

## **Parámetros que se estiman en un modelo GARCH(p, q)**
- μ (mu): Representa la media condicional de la serie temporal
- ω (omega): Es el término constante en la ecuación de la varianza condicional.
- α (alfa): Son los coeficientes de los términos ARCH; es decir, de los errores pasados al cuadrado.
- β (beta): Son los coeficientes de los términos GARCH; es decir, de la volatilidad condicional pasada.
  
## **Pruebas preliminares**
- Test de estacionariedad: Aplicar pruebas como ADF (Augmented Dickey-Fuller) o KPSS para verificar estacionariedad en la media.
- Detección de heterocedasticidad: Gráficos de autocorrelación (ACF/PACF) de los residuos al cuadrado.
- Test ARCH-LM (Lagrange Multiplier) para confirmar la presencia de efectos ARCH/GARCH.
- Distribución de los residuos: Verificar si presentan colas pesadas (usar curtosis) o asimetría, lo que sugiere usar distribuciones no normales (ej.: t-Student, GED).

## **Evaluación de la pertinencia del modelo**
- **Diagnóstico de residuos:**
  - Los residuos estandarizados deben ser ruido blanco (sin autocorrelación en ACF/PACF).
  - Aplicar tests como Ljung-Box o ARCH-LM a los residuos al cuadrado para confirmar que no quedan efectos ARCH.
- **Criterios de información:** Comparar modelos usando AIC, BIC, o Log-Likelihood.
- **Estabilidad:** Verificar si los parámetros son significativos (p-valores < 0.05).

# **Configuración y descarga de datos**

```python
!pip install yfinance
!pip install arch
```
```python
import pandas as pd
import numpy as np
import seaborn as sns
import matplotlib.pyplot as plt
import yfinance as yf
import scipy.stats as stats
import yfinance as yf
from arch import arch_model
from statsmodels.stats.diagnostic import het_arch
from statsmodels.stats.diagnostic import acorr_ljungbox
from statsmodels.tsa.stattools import acf, pacf
from typing import Union, List
from datetime import datetime, timedelta

def configure_analysis(stock, years=5):
    end_date = datetime.now()

    start_date = end_date - timedelta(days=years * 252)
    return start_date, end_date

def data_download(start_date, end_date, stock_symbols):
    try:
        prices = yf.download(stock_symbols, start=start_date, end=end_date)['Close']
        if isinstance(prices, pd.Series):
            prices = pd.DataFrame(prices)
        if prices.empty:
          raise ValueError("No se obtuvieron datos de precios")
        return prices
    except Exception as e:
        raise ValueError(f"Error al descargar datos: {str(e)}")
```
```python
if __name__ == "__main__":
    stock = ["COST"]
    start_date, end_date = configure_analysis(stock)
    try:
        prices = data_download(start_date, end_date, stock)
    except ValueError as e:
        print(f"Error al descargar datos: {e}")
        exit()
    print(f"Datos descargados:\n{prices.head()}\n")
```

 Ticker : COST

| Date | Close Price |
|------|-------------|
| 2021-09-13 | 439.327454 |
| 2021-09-14 | 438.132751 |
| 2021-09-15 | 440.350128 |
| 2021-09-16 | 442.816010 | 
| 2021-09-17 | 439.184143 |

# **Estadística y plot de precios inicial**
```python
for stock in prices.columns:
    print(prices.describe())
```
| Ticker | COST |
|--------|------|
| count | 865.000000 |
| mean | 613.269908 |
| std | 174.173290 |
| min | 399.907318 |
| 25% | 481.563629 |
| 50% | 530.753906 |
| 75% | 730.203247 |
| max | 1076.859985 |

```python
for stock in prices.columns:
    plt.figure(figsize=(10, 5))
    plt.plot(prices[stock], label=f"Precio de {stock}", color="violet")
    plt.title(f"Precio de {stock}")
    plt.xlabel("Año")
    plt.ylabel("Precio")
    plt.legend()
```
![image](https://github.com/user-attachments/assets/69670c60-b00f-43c4-a5ef-74dc85e2fc38)

# **Cálculo y gráfico de retornos logarítmicos**

```python
def log_returns(prices):
    log_retornos = np.log(prices / prices.shift(1)).dropna()
    if len(log_retornos) < 30:
        raise ValueError("No hay suficientes datos para calcular retornos.")
    return log_retornos

def plot_log_returns(log_retornos, stock):
    plt.figure(figsize=(10, 5))
    plt.plot(log_retornos[stock], label=f"Retornos Logarítmicos - {stock}", color="violet")
    plt.axhline(y=0, color="purple", linestyle="--", linewidth=0.7)
    plt.title(f"Retornos Logarítmicos de {stock}")
    plt.xlabel("Año")
    plt.ylabel("Log-retornos")
    plt.legend()
    plt.show()
```
```python
# Calcular retornos logarítmicos
retornos = log_returns(prices)
print(f"Retornos logarítmicos:\n{retornos.head()}\n")
plot_log_returns(retornos, stock)
```

Retornos logarítmicos:

Ticker :  COST

| Date | Log-retornos |
|------|--------------|
| 2021-09-14 | -0.002723 |
| 2021-09-15 | 0.005048 |
| 2021-09-16 | 0.005584 |
| 2021-09-17 | -0.008236 |
| 2021-09-20 | -0.018383 |


![image](https://github.com/user-attachments/assets/5434d653-df30-4270-a2a9-90c0c5af10d6)


