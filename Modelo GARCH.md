# Construcción de Modelo de Heterocedasticidad Condicional Autoregresiva Generalizada

# Importar librerías necesarias
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import yfinance as yf
from arch import arch_model
from datetime import datetime, timedelta

# 1. Parámetros y obtención de data histórica de la acción
def configure_analysis(stock, years=10):
    # Parámetros básicos
    end_date = datetime.now()
    start_date = end_date - timedelta(days=int(years * 252 * 0.7))  # Aproximación de días hábiles
    return start_date, end_date

# 2. Obtención de datos históricos
def data_download(start_date, end_date, stock_symbols):
    prices = yf.download(stock_symbols, start=start_date, end=end_date)['Close']
    return prices

# 3. Cálculo de retornos logarítmicos
def log_returns(prices):
    retornos = np.log(prices / prices.shift(1)).dropna()
    return retornos

# 4. Creación del Modelo GARCH
def garch_model(retornos):
    modelo = arch_model(retornos, vol='Garch', p=1, q=1)
    results = modelo.fit(disp="off")
    return results

# 5. Resumen del modelo
def model_summary(results):
    print(results.summary())

# 6. Graficar residuos estandarizados
def plot_residuals(results):
    plt.figure(figsize=(10, 6))
    plt.plot(results.std_resid, label="Residuos Estandarizados")
    plt.axhline(y=0, color="red", linestyle="--", linewidth=0.7)
    plt.title("Residuos Estandarizados")
    plt.legend()
    plt.show()

# 7. Diagnóstico del modelo
def diagnostic_plots(results):
    fig = results.plot(annualize="D")
    plt.show()

# 8. Testing del script
if __name__ == "__main__":
    stock = ["AMZN", "AAPL", "TSLA"]  #Símbolos de acciones
    start_date, end_date = configure_analysis(stock)

  # Descargar datos de precios
  prices = data_download(start_date, end_date, stock)
  print(f"Datos descargados:\n{prices.head()}\n")

  # Calcular retornos logarítmicos
  retornos = log_returns(prices)
  print(f"Retornos logarítmicos:\n{retornos.head()}\n")

  # Crear y ajustar el modelo GARCH
  results = garch_model(retornos["TSLA"])  #Usando Tesla como ejemplo
  model_summary(results)

  # Graficar residuos estandarizados
  plot_residuals(results)

  # Gráficos de diagnóstico
  diagnostic_plots(results)
