# **Construcción del Modelo de Heterocedasticidad Condicional Autorregresiva Generalizada**
![Python](https://img.shields.io/badge/Python-3.13-yellow)
![Status](https://img.shields.io/badge/Status-Complete-green)

Es un modelo econométrico que permite evaluar y modelar la volatilidad en series de tiempo financieras. Plantea que existe autocorrelación en la varianza de series temporales y; que esta no es constante en el tiempo. De manera que, reconoce que la volatilidad financiera no es uniforme y que los periodos de alta volatilidad tiende a generar clústeres.
La varianza depende tanto de errores pasados como de sus valores tomados en el pasado, puesto que los mercados no se comportan únicamente de manera aleatoria.

## **Especificación del modelo**

Orden del GARCH(p, q):
> - *p*: Número de términos autorregresivos de la varianza (GARCH).
> - *q*: Número de términos de los errores al cuadrado (ARCH).

## **Distribución de los errores:**

- Normal (Gaussiana).
- t-Student (para capturar colas pesadas).
- Distribución Generalizada de Errores (GED).
  
**Principales propiedades**
- **No estacionariedad** en la varianza.
- **Estacionariedad en la media:** La serie debe ser estacionaria en su componente de media. Caso contrario, se deben aplicar transformaciones como la diferenciación (para eliminar tendencias) o transformaciones log, Box-Cox para estabilizar la media.
- **Ausencia de autocorrelación en la media:** Si hay autocorrelación, primero se debe modelar la media con un proceso ARMA(p,q) mediante un modelo ARMA-GARCH
  
- Alpha debe ser positivo, así garantiza una varianza positiva.
- Los sucesos más recientes generan mayor efecto.
- La sumatoria de alpha y beta debe de permanecer entre 0 y 1

## **Parámetros que se estiman en un modelo GARCH(p, q)**
- *μ* (mu): Representa la media condicional de la serie temporal
- *ω* (omega): Es el término constante en la ecuación de la varianza condicional.
- *α* (alfa): Son los coeficientes de los términos ARCH; es decir, de los errores pasados al cuadrado.
- *β* (beta): Son los coeficientes de los términos GARCH; es decir, de la volatilidad condicional pasada.
  
## **Pruebas preliminares**
- **Test de estacionariedad:** Aplicar pruebas como ADF (Augmented Dickey-Fuller) o KPSS para verificar estacionariedad en la media.
- **Detección de heterocedasticidad:** Gráficos de autocorrelación (ACF/PACF) de los residuos al cuadrado.
- **Test ARCH-LM (Lagrange Multiplier)** para confirmar la presencia de efectos ARCH/GARCH.
- **Distribución de los residuos:** Verificar si presentan colas pesadas (usar curtosis) o asimetría, lo que sugiere usar distribuciones no normales (ej.: t-Student, GED).

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
```
[*********************100%***********************]  1 of 1 completedDatos descargados:
Ticker            COST
Date                  
2021-09-13  439.327454
2021-09-14  438.132751
2021-09-15  440.350128
2021-09-16  442.816010
2021-09-17  439.184143
```

# **Estadística y plot de precios inicial**

```python
for stock in prices.columns:
    print(prices.describe())
```

```
Ticker         COST
count    865.000000
mean     613.269908
std      174.173290
min      399.907318
25%      481.563629
50%      530.753906
75%      730.203247
max     1076.859985
```

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

```
Retornos logarítmicos:
Ticker          COST
Date                
2021-09-14 -0.002723
2021-09-15  0.005048
2021-09-16  0.005584
2021-09-17 -0.008236
2021-09-20 -0.018383
```

![image](https://github.com/user-attachments/assets/5434d653-df30-4270-a2a9-90c0c5af10d6)


# **Análisis estadístico de los retornos logarítmicos**

```python
def analyze_log_returns(log_retornos):
  stats = {}
  for column in log_retornos.columns:
    stats[column] = {
        'Media': log_retornos[column].mean(),
        'Mediana': log_retornos[column].median(),
        'Mínimo valor': log_retornos[column].min(),
        'Máximo valor': log_retornos[column].max(),
        'Desviación Estándar': log_retornos[column].std(),
        'Asimetría': log_retornos[column].skew(),
        'Curtosis': log_retornos[column].kurtosis()
    }
  return pd.DataFrame(stats)
```

```python
print(analyze_log_returns(retornos))
```

```
                          COST
Media                 0.000992
Mediana               0.001447
Mínimo valor         -0.132975
Máximo valor          0.070078
Desviación Estándar   0.014989
Asimetría            -0.945498
Curtosis             10.046149
```

# **Correlograma de log-retornos**
- **ACF (Autocorrelation Function)** mide la correlación entre una observación y sus rezagos sin ajustar por los efectos de los rezagos intermedios.
- **PACF (Partial ACF)** mide la correlación entre una observación y un rezago específico, eliminando el impacto de los rezagos intermedios.
  > - Si el PACF muestra un corte abrupto en un rezago específico, sugiere un modelo AR(p) de orden 𝑝
  > - Si el PACF se desvanece lentamente, puede ser indicio de un modelo más complejo (como un ARMA).

```python
def plot_correlogram(log_retornos: Union[pd.Series, pd.DataFrame], lags: int = 40, alpha: float = 0.05):
    """
    Crea un correlograma de ACF y PACF
    """
    def calcular_bandas_confianza(n_obs: int, alpha: float) -> float:
        return np.sqrt(1 / n_obs) * stats.norm.ppf(1 - alpha / 2)

    fig, axes = plt.subplots(2, 1, figsize=(10, 8))

    acf_vals = acf(log_retornos, nlags=lags, fft=False)
    pacf_vals = pacf(log_retornos, nlags=lags)

    bandas = calcular_bandas_confianza(len(log_retornos), alpha)

    axes[0].stem(range(lags + 1), acf_vals[:lags + 1], linefmt="b-", markerfmt="bo", basefmt="r-")
    axes[0].axhline(y=0, color="black", linestyle="-")
    axes[0].axhline(y=bandas, color="red", linestyle="--")
    axes[0].axhline(y=-bandas, color="red", linestyle="--")
    axes[0].set_title("ACF")

    axes[1].stem(range(1, lags + 1), pacf_vals[1:lags + 1], linefmt="b-", markerfmt="bo", basefmt="r-")
    axes[1].axhline(y=0, color="black", linestyle="-")
    axes[1].axhline(y=bandas, color="red", linestyle="--")
    axes[1].axhline(y=-bandas, color="red", linestyle="--")
    axes[1].set_title("PACF")

    plt.tight_layout()
    plt.show()
```

```python
plot_correlogram(retornos)
```
![image](https://github.com/user-attachments/assets/66d01f43-73ff-4c38-a06d-5217f8cd2d49)

# **Prueba ARCH-LM**
Evalúa si hay efectos ARCH en los residuos de la serie. Si el p-valor es bajo (<0.05), se rechaza la hipótesis nula de homocedasticidad, lo que sugiere la presencia de **heterocedasticidad condicional.**

# **Prueba de Ljung-Box en los residuos al cuadrado**
Verifica si hay autocorrelación en los residuos al cuadrado, lo que indica heterocedasticidad.

```python
def test_heteroskedasticity(log_retornos):
    """
    Realiza pruebas de heterocedasticidad en los retornos logarítmicos.

    Parámetros:
    log_retornos : pd.Series
        Serie de retornos logarítmicos.

    Retorna:
    dict : Resultados de las pruebas ARCH-LM y Ljung-Box.
    """

    resultados = {}

    for stock in log_retornos.columns:
        print(f"\nResultados para {stock}:\n" + "-"*40)

        # Prueba ARCH-LM
        arch_test = het_arch(log_retornos[stock])
        p_arch = arch_test[1]  # p-valor

        # Prueba Ljung-Box en residuos al cuadrado
        lb_test = acorr_ljungbox(log_retornos[stock]**2, lags=[10], return_df=True)
        p_ljung = lb_test["lb_pvalue"].values[0]

        resultados[stock] = {
            "ARCH-LM p-valor": p_arch,
            "Ljung-Box p-valor": p_ljung
        }

        # Interpretación de resultados
        print(f"ARCH-LM p-valor: {p_arch:.4f}")
        print(f"Ljung-Box p-valor: {p_ljung:.4f}")

        if p_arch < 0.05:
            print("Hay evidencia de heterocedasticidad (efectos ARCH detectados).")
        else:
            print("No hay evidencia significativa de heterocedasticidad.")

        if p_ljung < 0.05:
            print("Residuos al cuadrado presentan autocorrelación (indicio de heterocedasticidad).")
        else:
            print("No hay autocorrelación significativa en residuos al cuadrado.")

    return resultados
```

```python
test_heteroskedasticity(retornos)
```

```
Resultados para COST:
----------------------------------------
ARCH-LM p-valor: 0.0000
Ljung-Box p-valor: 0.0000
Hay evidencia de heterocedasticidad (efectos ARCH detectados).
Residuos al cuadrado presentan autocorrelación (indicio de heterocedasticidad).
{'COST': {'ARCH-LM p-valor': 3.2134229872156907e-06,
  'Ljung-Box p-valor': 4.993714787115107e-07}}
```

# **Implementación del Modelo GARCH**

```python
def fit_garch_model(log_retornos, stock, p=1, q=1):
    """
    Ajusta un modelo GARCH(p, q) a los retornos logarítmicos de un activo.

    Parámetros:
    -----------
    log_retornos : pd.DataFrame
        DataFrame con los retornos logarítmicos.
    stock : str
        Nombre del activo a modelar.
    p : int, opcional
        Número de términos ARCH (default: 1).
    q : int, opcional
        Número de términos GARCH (default: 1).

    Retorna:
    --------
    resultado : arch.univariate.base.ARCHModelResult
        Modelo GARCH ajustado.
    """

    # Validar parámetros p y q
    if not isinstance(p, int) or not isinstance(q, int) or p < 0 or q < 0:
        raise ValueError("Los parámetros p y q deben ser enteros no negativos.")

    print(f"\nAjustando modelo GARCH({p},{q}) para {stock}...\n" + "-"*50)

    # Validar si el stock está en el DataFrame
    if stock not in log_retornos.columns:
        raise KeyError(f"La columna '{stock}' no está en el DataFrame de retornos.")

    # Extraer y validar la serie de retornos
    serie = log_retornos[stock].dropna() * 100  # Convertimos a porcentaje
    if serie.empty:
        raise ValueError(f"La serie de retornos para {stock} está vacía después de eliminar NaN.")

    try:
        # Ajustar el modelo GARCH
        modelo = arch_model(serie, vol='Garch', p=p, q=q, dist='normal')
        resultado = modelo.fit(disp="off")

        # Mostrar resumen del modelo
        print("\n✅ Modelo ajustado correctamente.\n")
        print(resultado.summary())

        return resultado

    except Exception as e:
        print(f"\n❌ Error al ajustar el modelo GARCH: {e}")
        return None
```
```python
modelo_garch = fit_garch_model(retornos, stock, p=1, q=1)
```
```
Ajustando modelo GARCH(1,1) para COST...
--------------------------------------------------

✅ Modelo ajustado correctamente.

                     Constant Mean - GARCH Model Results                      
==============================================================================
Dep. Variable:                   COST   R-squared:                       0.000
Mean Model:             Constant Mean   Adj. R-squared:                  0.000
Vol Model:                      GARCH   Log-Likelihood:               -1535.97
Distribution:                  Normal   AIC:                           3079.94
Method:            Maximum Likelihood   BIC:                           3098.99
                                        No. Observations:                  864
Date:                Sun, Feb 23 2025   Df Residuals:                      863
Time:                        05:07:07   Df Model:                            1
                                Mean Model                                
==========================================================================
                 coef    std err          t      P>|t|    95.0% Conf. Int.
--------------------------------------------------------------------------
mu             0.1210  5.319e-02      2.275  2.292e-02 [1.674e-02,  0.225]
                              Volatility Model                             
===========================================================================
                 coef    std err          t      P>|t|     95.0% Conf. Int.
---------------------------------------------------------------------------
omega          0.0495  5.480e-02      0.904      0.366 [-5.786e-02,  0.157]
alpha[1]       0.0434  3.547e-02      1.223      0.221 [-2.614e-02,  0.113]
beta[1]        0.9355  5.051e-02     18.523  1.350e-76    [  0.837,  1.035]
===========================================================================

Covariance estimator: robust
```

# **Evaluación del modelo**

```python
## **Graficar volatilidad estimada**
def plot_garch_volatility(modelo, stock):
    """
    Grafica la volatilidad condicional estimada por el modelo GARCH 1.
    """
    plt.figure(figsize=(10,5))
    plt.plot(modelo.conditional_volatility, color="purple", label="Volatilidad Estimada")
    plt.title(f"Volatilidad Condicional Estimada - {stock}")
    plt.xlabel("Fecha")
    plt.ylabel("Volatilidad (%)")
    plt.legend()
    plt.show()

plot_garch_volatility(modelo_garch, stock=list({stock}))
```
![image](https://github.com/user-attachments/assets/4ce2ab2b-bcc8-4e64-8968-f4c556285f45)

# **Verificar residuos del modelo**
```python
def check_garch_residuals(modelo):
    """
    Analiza los residuos estándar del modelo GARCH.
    """
    residuos = modelo.resid / modelo.conditional_volatility

    plt.figure(figsize=(10,5))
    sns.histplot(residuos, bins=30, kde=True, color="purple")
    plt.axvline(x=0, color="black", linestyle="--")
    plt.title("Distribución de los Residuos Estandarizados")
    plt.show()

    print("\n📌 Prueba Ljung-Box en residuos estandarizados:")
    lb_test = acorr_ljungbox(residuos, lags=[10], return_df=True)
    print(lb_test)

check_garch_residuals(modelo_garch)
```
![image](https://github.com/user-attachments/assets/309116ec-ee1d-4e31-a439-3b27e878fe81)

```
📌 Prueba Ljung-Box en residuos estandarizados:
     lb_stat  lb_pvalue
10  9.844192   0.454268
```

### **Prueba de Ljung-Box:**
Evalúa si hay autocorrelación en los residuos
> - Si p-valor > 0.05: No hay autocorrelación (bueno)
> - Si p-valor < 0.05: Existe autocorrelación (problema)

# **Optimización de (p, q) en el modelo GARCH con criterios de información (AIC/BIC)**

```python
import itertools
def optimize_garch(log_retornos, stock, p_range=3, q_range=3):
    """
    Encuentra la mejor combinación de (p, q) para un modelo GARCH usando AIC y BIC.

    Parámetros:
    -----------
    log_retornos : pd.DataFrame
        DataFrame con los retornos logarítmicos.
    stock : str
        Nombre del activo a modelar.
    p_range : int, opcional
        Máximo rezago p a evaluar (default: 3).
    q_range : int, opcional
        Máximo rezago q a evaluar (default: 3).

    Retorna:
    --------
    dict : Mejor modelo basado en AIC y BIC.
    """

    print(f"\nOptimizando GARCH(p,q) para {stock}...\n" + "-"*50)

    best_aic = float('inf')
    best_bic = float('inf')
    best_model_aic = None
    best_model_bic = None
    best_pq_aic = None
    best_pq_bic = None

    # Serie de retornos escalada
    serie = log_retornos[stock] * 100

    for p, q in itertools.product(range(p_range + 1), repeat=2):  # Prueba todas las combinaciones (p,q)
        if p == 0 and q == 0:  # Evitar modelo sin ARCH ni GARCH
            continue

        try:
            modelo = arch_model(serie, vol='Garch', p=p, q=q, dist='normal')
            resultado = modelo.fit(disp="off")

            if resultado.aic < best_aic:
                best_aic = resultado.aic
                best_model_aic = resultado
                best_pq_aic = (p, q)

            if resultado.bic < best_bic:
                best_bic = resultado.bic
                best_model_bic = resultado
                best_pq_bic = (p, q)

            print(f"GARCH({p},{q}) → AIC: {resultado.aic:.3f} | BIC: {resultado.bic:.3f}")

        except:
            print(f"⚠️ No se pudo estimar GARCH({p},{q})")

    print("\n📌 **Mejor modelo según AIC:** GARCH", best_pq_aic)
    print("📌 **Mejor modelo según BIC:** GARCH", best_pq_bic)

    return {
        "best_aic_model": best_model_aic,
        "best_bic_model": best_model_bic,
        "best_pq_aic": best_pq_aic,
        "best_pq_bic": best_pq_bic
    }

best_models = optimize_garch(log_retornos=retornos, stock=list({stock}), p_range=3, q_range=3)

# Extraemos el mejor modelo
best_garch_model = best_models["best_aic_model"]
```
```
Optimizando GARCH(p,q) para ['COST']...
--------------------------------------------------
⚠️ No se pudo estimar GARCH(0,1)
⚠️ No se pudo estimar GARCH(0,2)
⚠️ No se pudo estimar GARCH(0,3)
GARCH(1,0) → AIC: 3149.428 | BIC: 3163.713
GARCH(1,1) → AIC: 3079.945 | BIC: 3098.991
GARCH(1,2) → AIC: 3081.773 | BIC: 3105.581
GARCH(1,3) → AIC: 3082.418 | BIC: 3110.987
GARCH(2,0) → AIC: 3150.806 | BIC: 3169.852
GARCH(2,1) → AIC: 3081.945 | BIC: 3105.752
GARCH(2,2) → AIC: 3083.647 | BIC: 3112.216
GARCH(2,3) → AIC: 3084.418 | BIC: 3117.749
GARCH(3,0) → AIC: 3137.201 | BIC: 3161.009
GARCH(3,1) → AIC: 3083.945 | BIC: 3112.514
GARCH(3,2) → AIC: 3085.773 | BIC: 3119.104
GARCH(3,3) → AIC: 3086.092 | BIC: 3124.185

📌 **Mejor modelo según AIC:** GARCH (1, 1)
📌 **Mejor modelo según BIC:** GARCH (1, 1)
```
# **Gráfico de volatilidad condicional**

```python
def plot_volatility(modelo, stock):
    plt.figure(figsize=(10, 5))
    plt.plot(modelo.conditional_volatility, color='purple', label='Volatilidad Condicional')
    plt.title(f'Volatilidad Condicional GARCH - {stock}')
    plt.xlabel('Tiempo')
    plt.ylabel('Volatilidad')
    plt.legend()
    plt.show()

plot_volatility(best_garch_model, stock=list({stock}))
```
![image](https://github.com/user-attachments/assets/70b2f1d3-8e4a-4e6f-8c48-57294419282a)

```python
def evaluate_residuals(modelo):
    residuos = modelo.resid / modelo.conditional_volatility
    plt.figure(figsize=(10, 5))
    plt.plot(residuos, label='Residuos estandarizados', color='violet')
    plt.axhline(y=0, color='black', linestyle='--')
    plt.title('Residuos Estandarizados del Modelo GARCH')
    plt.legend()
    plt.show()
    print("Ljung-Box Test para autocorrelación de residuos:")
    print(acorr_ljungbox(residuos, lags=[10], return_df=True))
    print("\nPrueba Jarque-Bera para normalidad de residuos:")
    print(stats.jarque_bera(residuos))

evaluate_residuals(best_garch_model)
```

![image](https://github.com/user-attachments/assets/b3d5c542-9a8b-4a70-8a17-95796136981f)

```
Ljung-Box Test para autocorrelación de residuos:
     lb_stat  lb_pvalue
10  9.844192   0.454268

Prueba Jarque-Bera para normalidad de residuos:
SignificanceResult(statistic=1610.433986856194, pvalue=0.0)
```

## **Observación:**
No es cierto que siempre deba eliminarse toda autocorrelación después de un GARCH. La clave es:

En la media: Los residuos crudos deben ser ruido blanco (gracias al modelo ARMA).

En la varianza: Los residuos estandarizados al cuadrado deben ser ruido blanco (gracias al GARCH).

# **Proyección de volatilidad**

```python
def proyectar_volatilidad(log_retornos, stock, p=1, q=1, horizonte=30):
    """
    Ajusta un modelo GARCH(p, q) y proyecta la volatilidad futura.

    Parámetros:
    -----------
    log_retornos : pd.DataFrame
        DataFrame con los retornos logarítmicos.
    stock : str
        Nombre del activo a modelar.
    p : int, opcional
        Número de términos ARCH (default: 1).
    q : int, opcional
        Número de términos GARCH (default: 1).
    horizonte : int, opcional
        Número de días para proyectar la volatilidad.

    Retorna:
    --------
    forecast_volatility : np.array
        Proyección de la volatilidad futura.
    """

    print(f"\nProyectando volatilidad con GARCH({p},{q}) para {stock}...\n" + "-"*50)

    # Validar si el stock está en los datos
    if stock not in log_retornos.columns:
        raise KeyError(f"⚠️ La columna '{stock}' no está en el DataFrame de retornos.")

    # Extraer y limpiar la serie de retornos
    serie = log_retornos[stock].dropna() * 100  # Convertimos a porcentaje
    if serie.empty:
        raise ValueError(f"⚠️ La serie de retornos para {stock} está vacía después de eliminar NaN.")

    # Ajustar el modelo GARCH
    modelo = arch_model(serie, vol='Garch', p=p, q=q, dist='normal')
    resultado = modelo.fit(disp="off")

    # Generar la predicción de la varianza condicional
    garch_forecast = resultado.forecast(start=0, horizon=horizonte)

    # Extraer la varianza condicional esperada y convertirla en desviación estándar
    forecast_variance = garch_forecast.variance.iloc[-1].values  # Última fila de varianzas
    forecast_volatility = np.sqrt(forecast_variance)  # Volatilidad esperada

    print(f"\nProyección de volatilidad ({horizonte} días):\n", forecast_volatility)

    return forecast_volatility

volatilidad_futura = proyectar_volatilidad(retornos, stock='COST', p=1, q=1, horizonte=30)
```
```
Proyectando volatilidad con GARCH(1,1) para COST...
--------------------------------------------------

Proyección de volatilidad (30 días):
[1.367389   1.37108417 1.3746918  1.37821421 1.38165365 1.38501229
1.38829223 1.39149553 1.39462416 1.39768003 1.40066501 1.40358089
1.40642944 1.40921234 1.41193125 1.41458776 1.41718344 1.41971978
1.42219827 1.42462031 1.4269873  1.42930058 1.43156146 1.43377122
1.43593108 1.43804226 1.44010593 1.44212322 1.44409524 1.44602308]
```
