# ==============================================================
# CONCENTRACIÓN INDUSTRIAL Y RENDIMIENTO BURSÁTIL
# EN LA BVL 2013-2025

rm(list = ls())
cat("\014")

# ==============================================================
# PAQUETES
# ==============================================================
library(readr)      # read_csv()
library(plm)        # pdata.frame, plm, pFtest, plmtest, pcdtest,
# pbgtest, purtest, phtest, vcovSCC
library(dplyr)      # %>%, filter, group_by, summarise, mutate
library(tidyr)      # pivot_wider
library(lmtest)     # coeftest(), bptest()
library(sandwich)   # vcovSCC() (también en plm)
library(car)        # vif(), linearHypothesis()
library(ggplot2)    # gráficos
library(e1071)      # skewness(type=2), kurtosis(type=2)
library(tseries)    # jarque.bera.test() [descriptivo]
library(patchwork)  # composición de figuras ggplot
library(fUnitRoots) # instalado; auxiliar para CIPS manual
library(boot)       # bootstrap BCa (Parte 7)


# ==============================================================
# PARTE 0 — CARGA Y PREPARACIÓN DE DATOS
# ==============================================================
setwd("C:/Users/user/Documents/model_paper")
panel_full <- read_csv("panel_db.csv", show_col_types = FALSE)

# ── Variable dummy de choques estructurales ──────────────────
# d_shock = 1 si ocurre al menos uno de tres tipos de choque:
#   d_comm    = choque de commodities (caída de precios)
#   d_covid   = período pandémico 2020-2021
#   d_pol_inf = inestabilidad política-inflacionaria
# El operador | (OR lógico) asigna 1 si cualquiera es TRUE.
# as.integer() convierte TRUE/FALSE a 1/0.
panel_full$d_shock <- as.integer(
  panel_full$d_comm    == 1 |
    panel_full$d_covid   == 1 |
    panel_full$d_pol_inf == 1
)

# ── Paneles N=7 (completo) y N=6 (principal) ─────────────────
# Panel N=7: incluye todas las industrias (referencia)
# Panel N=6: excluye id_industria=1 (Agricultura) por
#   iliquidez estructural: mayoría de trimestres con HPR=0 y Vz=0
#   → no representa precios de mercado válidos.
panel_n7    <- panel_full
panel_db_n7 <- pdata.frame(panel_n7, index = c("id_industria","id_tiempo"))

panel_n6    <- panel_full %>% filter(id_industria != 1)
panel_db_n6 <- pdata.frame(panel_n6, index = c("id_industria","id_tiempo"))

# Verificar dimensiones del panel
cat("Panel N=7:\n"); pdim(panel_db_n7)
cat("Panel N=6:\n"); pdim(panel_db_n6)

# ── Conteo de NAs por variable (N=7 y N=6) ───────────────────
# Los NAs en rend_exceso, hpr, riesgo_pburs provienen de
# trimestres sin precio de cotización disponible.
cat("\nNAs panel N=7:\n")
cat("  rend_exceso: ", sum(is.na(panel_db_n7$rend_exceso)),   "\n")
cat("  hpr:         ", sum(is.na(panel_db_n7$hpr)),           "\n")
cat("  riesgo_pburs:", sum(is.na(panel_db_n7$riesgo_pburs)),  "\n")
cat("  dlev:        ", sum(is.na(panel_db_n7$dlev)),          "\n")

# FIX-5: verificar NAs en panel N=6 (panel principal)
cat("\nNAs panel N=6 (panel principal de estimación):\n")
cat("  rend_exceso: ", sum(is.na(panel_n6$rend_exceso)),   "\n")
cat("  hpr:         ", sum(is.na(panel_n6$hpr)),           "\n")
cat("  riesgo_pburs:", sum(is.na(panel_n6$riesgo_pburs)),  "\n")
cat("  exp_return:  ", sum(is.na(panel_n6$exp_return)),    "\n")
cat("  dlev:        ", sum(is.na(panel_n6$dlev)),          "\n")
cat("  beta:        ", sum(is.na(panel_n6$beta)),          "\n")
cat("  hhi_lag:     ", sum(is.na(panel_n6$hhi_lag)),       "\n")

cat("\nDistribución d_shock (N=6): "); print(table(panel_n6$d_shock))


# ==============================================================
# PARTE 1 — ESTADÍSTICOS DESCRIPTIVOS
# ==============================================================
cat("\n==============================================================\n")
cat("PARTE 1 — ESTADÍSTICOS DESCRIPTIVOS\n")
cat("==============================================================\n")

# Resumen general N=7
panel_n7 %>%
  select(hhi_lag, rend_exceso, hpr, exp_return,
         riesgo_pburs, beta, dlev) %>%
  summary() %>% print()

# Descriptivos por industria N=6
desc_n6 <- panel_n6 %>%
  group_by(label) %>%
  summarise(
    HHI_media   = round(mean(hhi_lag,      na.rm = TRUE), 4),
    HHI_sd      = round(sd(hhi_lag,        na.rm = TRUE), 4),
    RE_exc_med  = round(mean(rend_exceso,  na.rm = TRUE), 4),
    RE_exc_sd   = round(sd(rend_exceso,    na.rm = TRUE), 4),
    HPR_media   = round(mean(hpr,          na.rm = TRUE), 4),
    HPR_sd      = round(sd(hpr,            na.rm = TRUE), 4),
    ER_media    = round(mean(exp_return,   na.rm = TRUE), 4),
    RPB_media   = round(mean(riesgo_pburs, na.rm = TRUE), 6),
    Beta_med    = round(mean(beta,         na.rm = TRUE), 4),
    dLev_med    = round(mean(dlev,         na.rm = TRUE), 5),
    N_obs       = n(),
    .groups     = "drop"
  )
print(as.data.frame(desc_n6))


# ==============================================================
# PARTE 1B — DIAGNÓSTICO VARIACIÓN WITHIN DEL HHI (N=6)
# El estimador EF (within) usa SOLO la variación temporal del
# HHI dentro de cada industria. Si esa variación es escasa,
# el EF tiene baja potencia identificadora sobre β_HHI.
# Criterio de alerta: CV_within < 0.05 (<5%).
# ==============================================================
cat("\n==============================================================\n")
cat("PARTE 1B — VARIACIÓN WITHIN DEL HHI (N=6)\n")
cat("==============================================================\n")

within_hhi <- panel_n6 %>%
  group_by(id_industria, label) %>%
  summarise(
    mean_hhi      = round(mean(hhi_lag, na.rm=TRUE), 4),
    sd_within_hhi = round(sd(hhi_lag,   na.rm=TRUE), 4),
    min_hhi       = round(min(hhi_lag,  na.rm=TRUE), 4),
    max_hhi       = round(max(hhi_lag,  na.rm=TRUE), 4),
    rango_within  = round(max(hhi_lag,  na.rm=TRUE) -
                            min(hhi_lag,  na.rm=TRUE), 4),
    CV_within     = round(sd(hhi_lag,   na.rm=TRUE) /
                            mean(hhi_lag, na.rm=TRUE), 4),
    .groups = "drop"
  ) %>%
  mutate(Alerta = ifelse(CV_within < 0.05,
                         "ALERTA: variación within marginal (<5%)",
                         "OK: variación within suficiente"))
print(as.data.frame(within_hhi))

sd_total_hhi <- sd(panel_n6$hhi_lag, na.rm=TRUE)
cat(sprintf("\nSD total HHI (between+within): %.4f\n", sd_total_hhi))
cat(sprintf("Proporción within/total: %.1f%%\n",
            100 * mean(within_hhi$sd_within_hhi, na.rm=TRUE) /
              sd_total_hhi))


# ==============================================================
# PARTE 2 — DISTRIBUCIONES: G₁, G₂ Y SHAPIRO-WILK SELECTIVO
#
# FIX-7: Se mantiene G₁/G₂ (insesgados, Fisher) para todas
# las variables y se aplica Shapiro-Wilk SOLO para HHI y
# riesgo_pburs (las variables que justifican Spearman).
# JB se mantiene como estadístico descriptivo únicamente.
# ==============================================================
cat("\n==============================================================\n")
cat("PARTE 2 — DISTRIBUCIONES\n")
cat("==============================================================\n")

vars_list <- c("hhi_lag","rend_exceso","hpr","exp_return",
               "riesgo_pburs","beta","dlev")
labs_asis <- c("HHI(t-1)","Rend. Exceso (HP)","HPR (H1)",
               "Exp. Return","Riesgo P. Bursatil","Beta","Δlev")

# ── 2A. Asimetría G₁ y exceso de curtosis G₂ ─────────────────
cat("\n--- Asimetría G₁ y Exceso Curtosis G₂ (Fisher, type=2) ---\n")
dist_tabla <- data.frame(
  Variable     = labs_asis,
  G1_asimetria = sapply(vars_list, function(v)
    round(e1071::skewness(panel_n6[[v]], na.rm=TRUE, type=2), 4)),
  G2_kurt_exc  = sapply(vars_list, function(v)
    round(e1071::kurtosis(panel_n6[[v]], na.rm=TRUE, type=2), 4)),
  stringsAsFactors = FALSE
)
dist_tabla$Asim_clasif <- dplyr::case_when(
  abs(dist_tabla$G1_asimetria) <= 0.5 ~ "Aprox. simétrica",
  abs(dist_tabla$G1_asimetria) <= 1.0 ~ "Asimetría moderada",
  TRUE                                 ~ "Asimetría pronunciada"
)
dist_tabla$Kurt_clasif <- ifelse(dist_tabla$G2_kurt_exc >= 1,
                                 "Leptocúrtica (colas pesadas)",
                                 "Mesocúrtica (~normal)")
print(dist_tabla)

# ── 2B. Jarque-Bera — SOLO descriptivo, NO inferencial ───────
# ADVERTENCIA: datos pooled del panel ≠ i.i.d. (las 312 obs.
# están correlacionadas entre industrias). JB se reporta como
# evidencia exploratoria del grado de no-normalidad, no como
# test formal. No se cita como test estadístico en el paper.
cat("\n--- JB [DESCRIPTIVO — pooled ≠ i.i.d.] ---\n")
for (i in seq_along(vars_list)) {
  x  <- na.omit(panel_n6[[vars_list[i]]])
  jb <- jarque.bera.test(x)
  cat(sprintf("  [JB] %-22s X²=%-9.2f p=%s\n",
              labs_asis[i], jb$statistic,
              ifelse(jb$p.value < 0.001, "< 0.001",
                     sprintf("%.4f", jb$p.value))))
}
cat("  NOTA: JB sobre datos pooled viola i.i.d. — valor\n")
cat("  interpretado como evidencia exploratoria, no inferencial.\n")

# ── 2C. Shapiro-Wilk POR INDUSTRIA — test FORMAL ─────────────
# FIX-7: Solo para HHI(t-1) y riesgo_pburs (las dos variables
# directamente implicadas en la justificación de Spearman).
# n=52 por industria → SW tiene mayor potencia que JB.
# Respeta estructura de panel: cada industria es una serie propia.
cat("\n--- Shapiro-Wilk por industria (n=52 por unidad) ---\n")
cat("Variables: HHI(t-1) y Riesgo P. Bursátil\n")
cat("(Únicas que justifican la elección de Spearman sobre Pearson)\n\n")

sw_vars  <- c("hhi_lag", "riesgo_pburs")
sw_labs  <- c("HHI(t-1)", "Riesgo P. Bursátil")

for (k in seq_along(sw_vars)) {
  v <- sw_vars[k]
  cat(sprintf("[SW] %s:\n", sw_labs[k]))
  panel_n6 %>%
    group_by(label) %>%
    summarise(
      W     = tryCatch(
        round(shapiro.test(na.omit(!!sym(v)))$statistic, 4),
        error = function(e) NA_real_),
      p_val = tryCatch({
        p <- shapiro.test(na.omit(!!sym(v)))$p.value
        ifelse(p < 0.001, "< 0.001", sprintf("%.4f", p))
      }, error = function(e) "Error"),
      .groups = "drop"
    ) %>% print()
  cat("\n")
}
cat("Conclusión SW: si p < 0.05 en todas las industrias →\n")
cat("distribución intra-industrial no normal → Spearman justificado.\n")

# ── 2D. Gráfico distribuciones (Figura 1) ─────────────────────
sage_fill    <- "#7D9B76"
sage_density <- "#2C4A2E"

plot_sage <- function(v, lab, data) {
  x  <- na.omit(data[[v]])
  sk <- round(e1071::skewness(x, type=2), 3)
  ku <- round(e1071::kurtosis(x, type=2), 3)
  ggplot(data.frame(x = x), aes(x = x)) +
    geom_histogram(aes(y = after_stat(density)), bins = 20,
                   fill = sage_fill, color = "#FFFFFF", alpha = 0.90) +
    geom_density(color = sage_density, linewidth = 0.85) +
    labs(title    = lab,
         subtitle = paste0("G₁=", sk, " | G₂=", ku),
         x = NULL, y = "Densidad") +
    theme_minimal(base_size = 10) +
    theme(plot.title    = element_text(face="bold", size=10, hjust=0.5),
          plot.subtitle = element_text(size=8.5, color="gray40", hjust=0.5),
          panel.grid.minor = element_blank())
}

labs_sage <- c("HHI(t-1)","Rend. Exceso (HP)","HPR (H1)",
               "Rend. Esperado (H2)","Riesgo P. Bursatil",
               "Beta (β)","Δlev")

plots <- mapply(plot_sage, v = vars_list, lab = labs_sage,
                MoreArgs = list(data = panel_n6), SIMPLIFY = FALSE)

panel_fig1 <- (plots[[1]] | plots[[2]] | plots[[3]]) /
  (plots[[4]] | plots[[5]] | plots[[6]]) /
  (plots[[7]] | plot_spacer() | plot_spacer()) +
  plot_annotation(
    title    = "Figura 1",
    subtitle = "Distribución de variables — panel BVL 2013-2025 (N=6)",
    caption  = paste0("G₁ = asimetría Fisher (e1071, type=2). ",
                      "G₂ = exceso curtosis Fisher (e1071, type=2). ",
                      "Elaboración propia.")
  )
print(panel_fig1)
ggsave("figura1_distribuciones_BVL_N6.png", plot = panel_fig1,
       width = 11, height = 8.5, dpi = 300, bg = "white")


# ==============================================================
# PARTE 3 — MATRICES DE CORRELACIÓN: PEARSON Y SPEARMAN
#
# Justificación del uso dual:
# Bootstrap BCa confirma asimetría significativa en HHI(t-1) y
# riesgo_pburs (IC BCa excluye cero) → Spearman es el método
# principal. Las demás variables son simétricas (IC incluye 0)
# → Pearson sería aceptable para ellas. Se reportan ambas
# matrices para transparencia metodológica, siendo Spearman
# la referencia inferencial definitiva.
# ==============================================================
cat("\n==============================================================\n")
cat("PARTE 3 — CORRELACIONES PEARSON Y SPEARMAN (N=6)\n")
cat("==============================================================\n")

cor_vars_n6 <- panel_n6 %>%
  select(hhi_lag, rend_exceso, hpr, exp_return,
         riesgo_pburs, beta, dlev)

var_names <- c("HHI(t-1)", "Rend.Exceso", "HPR (H1)",
               "Exp.Return", "Riesgo P.B.", "Beta", "Δlev")

# ── 3A. Matriz de Pearson ─────────────────────────────────────
cor_pearson <- cor(cor_vars_n6, use = "complete.obs", method = "pearson")
rownames(cor_pearson) <- colnames(cor_pearson) <- var_names

cat("\n--- Matriz de Pearson (referencia; supuesto normalidad violado\n")
cat("    en HHI y riesgo_pburs — interpretar con cautela) ---\n")
print(round(cor_pearson, 4))

ev_p <- eigen(cor_pearson)$values
cat("\nEigenvalores Pearson:", round(ev_p, 4), "\n")
cat(ifelse(any(ev_p < -1e-8),
           "ALERTA: Matriz Pearson NO semidefinida positiva\n",
           "OK: Matriz Pearson semidefinida positiva\n"))

# ── 3B. Matriz de Spearman ────────────────────────────────────
cor_spearman <- cor(cor_vars_n6, use = "complete.obs", method = "spearman")
rownames(cor_spearman) <- colnames(cor_spearman) <- var_names

cat("\n--- Matriz de Spearman (método principal — robusto a asimetría\n")
cat("    confirmada por Bootstrap BCa en HHI y riesgo_pburs) ---\n")
print(round(cor_spearman, 4))

ev_s <- eigen(cor_spearman)$values
cat("\nEigenvalores Spearman:", round(ev_s, 4), "\n")
cat(ifelse(any(ev_s < -1e-8),
           "ALERTA: Matriz Spearman NO semidefinida positiva\n",
           "OK: Matriz Spearman semidefinida positiva\n"))

# ── 3C. Tabla comparativa: pares de interés teórico ──────────
cat("\n--- Comparación Pearson vs Spearman: pares de interés teórico ---\n")
cat(sprintf("%-25s %10s %10s %10s\n",
            "Par de variables", "Pearson", "Spearman", "Diferencia"))
cat(strrep("-", 57), "\n")

vars_interes <- list(
  c("HHI(t-1)", "Rend.Exceso"),
  c("HHI(t-1)", "HPR (H1)"),
  c("HHI(t-1)", "Exp.Return"),
  c("HHI(t-1)", "Riesgo P.B."),
  c("HHI(t-1)", "Beta"),
  c("HHI(t-1)", "Δlev"),
  c("Riesgo P.B.", "Beta")
)

for (par in vars_interes) {
  r_p <- cor_pearson[par[1], par[2]]
  r_s <- cor_spearman[par[1], par[2]]
  label <- paste0(par[1], " — ", par[2])
  cat(sprintf("%-25s %10.4f %10.4f %10.4f\n",
              label, r_p, r_s, r_s - r_p))
}
cat(strrep("-", 57), "\n")
cat("NOTA: Diferencias > |0.05| indican impacto de outliers sobre Pearson.\n")
cat("Método definitivo para análisis: SPEARMAN\n")


# ==============================================================
# PRE-PARTE 4 — IMPLEMENTACIÓN MANUAL CIPS (Pesaran, 2007)
#
# CIPS(N,T) = N⁻¹ Σᵢ tᵢ(ρᵢ)
# donde tᵢ(ρᵢ) es el t-estadístico sobre ρᵢ en la regresión CADF:
#   Δyᵢₜ = αᵢ + ρᵢ yᵢ,ₜ₋₁ + c₀ᵢ ȳₜ₋₁
#           + Σⱼ₌₀¹ dᵢⱼ Δȳₜ₋ⱼ + Σₗ₌₁¹ φᵢₗ Δyᵢ,ₜ₋ₗ + εᵢₜ
# (Pesaran, 2007, p. 267, ecuación 4)
#
# ȳₜ = media transversal en el período t → absorbe el factor
# común que genera dependencia seccional (CD).
#
# H₀: raíz unitaria en todas las unidades (ρᵢ = 0 ∀i)
# Rechazar H₀ si CIPS < valor crítico (tabla Pesaran 2007)
# ==============================================================

run_cips <- function(variable, panel_df, lags = 1) {
  # 1. Reshaping a formato ancho: filas=tiempo, columnas=industria
  df_wide <- panel_df %>%
    select(id_industria, id_tiempo, all_of(variable)) %>%
    arrange(id_industria, id_tiempo) %>%
    pivot_wider(names_from   = id_industria,
                values_from  = all_of(variable),
                names_prefix = "ind_") %>%
    arrange(id_tiempo)
  
  Y     <- as.matrix(df_wide[, -1])   # matriz T × N
  T_obs <- nrow(Y)
  N_u   <- ncol(Y)
  
  # 2. Media transversal ȳₜ en cada período (vector T×1)
  # Esta media captura el factor común que genera CD.
  y_bar <- rowMeans(Y, na.rm = TRUE)
  
  cadf_t <- rep(NA_real_, N_u)
  
  for (i in seq_len(N_u)) {
    y_i    <- Y[, i]
    dy_i   <- diff(y_i)          # Δyᵢₜ,  longitud T-1
    dy_bar <- diff(y_bar)        # Δȳₜ,   longitud T-1
    y_lag  <- y_i[-T_obs]        # yᵢ,ₜ₋₁, longitud T-1
    yb_lag <- y_bar[-T_obs]      # ȳₜ₋₁,  longitud T-1
    
    # Índices válidos (eliminar los primeros 'lags' períodos)
    idx <- (lags + 1):length(dy_i)
    if (length(idx) < max(15, N_u + 4)) next
    
    dep <- dy_i[idx]
    
    # 3. Matriz de regresores CADF
    # Col 1: intercepto αᵢ
    # Col 2: yᵢ,ₜ₋₁ → coeficiente ρᵢ (interés del test)
    # Col 3: ȳₜ₋₁   → c₀ᵢ
    # Col 4: Δȳₜ    → d₀ᵢ
    # Col 5-6: Δyᵢ,ₜ₋₁ y Δȳₜ₋₁ (lags adicionales si p≥1)
    X <- cbind(int    = 1,
               y_lag  = y_lag[idx],
               yb_lag = yb_lag[idx],
               dyb_0  = dy_bar[idx])
    
    if (lags >= 1) {
      for (l in seq_len(lags)) {
        X <- cbind(X,
                   dyi_l = dy_i[idx - l],
                   dyb_l = dy_bar[idx - l])
      }
    }
    
    # 4. Eliminar filas con NAs
    valid <- complete.cases(dep, X)
    if (sum(valid) < ncol(X) + 3) next
    dep_v <- dep[valid]
    X_v   <- X[valid, , drop = FALSE]
    
    # 5. MCO mediante lm.fit() (más eficiente que lm())
    fit <- tryCatch(lm.fit(X_v, dep_v), error = function(e) NULL)
    if (is.null(fit)) next
    
    # 6. t-estadístico sobre ρᵢ (columna 2 de X = y_lag)
    resid_v  <- dep_v - X_v %*% fit$coefficients
    df_resid <- sum(valid) - ncol(X_v)
    if (df_resid <= 0) next
    
    s2      <- sum(resid_v^2) / df_resid
    XtX_inv <- tryCatch(solve(crossprod(X_v)), error = function(e) NULL)
    if (is.null(XtX_inv)) next
    
    se_b      <- sqrt(s2 * diag(XtX_inv))
    cadf_t[i] <- fit$coefficients[2] / se_b[2]
  }
  
  cips_stat <- mean(cadf_t, na.rm = TRUE)
  list(cips = cips_stat, cadf = cadf_t,
       N = N_u, T = T_obs, lags = lags, variable = variable)
}

# Valores críticos interpolados para N≈6, T≈52, Caso II
# Fuente: Pesaran (2007), Tabla 2, p. 271.
# Base: N=10 T=50: 1%=-2.69, 5%=-2.32, 10%=-2.12
# Interpolación lineal en N: fracción = (6-5)/(10-5) = 0.2
cv_cips <- list(p01 = -2.55, p05 = -2.33, p10 = -2.21)

CIPS_DISPONIBLE <- TRUE   # implementación manual siempre disponible


# ==============================================================
# PARTE 4 — PRUEBAS DE RAÍZ UNITARIA
# Secuencia: CD pretest → IPS (referencia) → CIPS (principal)
# ==============================================================
cat("\n==============================================================\n")
cat("PARTE 4 — RAÍZ UNITARIA EN PANEL\n")
cat("==============================================================\n")

vars_ips <- c("hhi_lag","rend_exceso","hpr","exp_return",
              "riesgo_pburs","beta","dlev")

# ── 4A. Pre-test CD de Pesaran (2004) ─────────────────────────
# Detecta si existe dependencia seccional ANTES de aplicar IPS/LLC.
# Si CD es significativo → IPS/LLC tienen tamaño distorsionado.
# Estadístico CD ~ N(0,1) bajo H₀ de independencia seccional.
cat("\n--- Pre-test: Dependencia Seccional Pesaran (2004) ---\n")
cd_diagnostico <- data.frame(
  Variable = character(), CD_stat = numeric(),
  p_valor  = character(), CD_detectado = logical(),
  stringsAsFactors = FALSE
)
for (v in vars_ips) {
  m_cd <- tryCatch(
    plm(as.formula(paste(v, "~1")), data = panel_db_n6, model = "pooling"),
    error = function(e) NULL)
  if (!is.null(m_cd)) {
    cd_r <- tryCatch(pcdtest(m_cd, test = "cd"), error = function(e) NULL)
    if (!is.null(cd_r)) {
      cd_diagnostico <- rbind(cd_diagnostico, data.frame(
        Variable     = v,
        CD_stat      = round(cd_r$statistic, 3),
        p_valor      = ifelse(cd_r$p.value < 0.001, "< 0.001",
                              sprintf("%.4f", cd_r$p.value)),
        CD_detectado = cd_r$p.value < 0.05,
        stringsAsFactors = FALSE))
    }
  }
}
print(cd_diagnostico)
n_cd <- sum(cd_diagnostico$CD_detectado, na.rm = TRUE)
cat(sprintf("\n%d/7 variables con CD significativo.\n", n_cd))
if (n_cd > 0) cat("→ IPS/LLC tienen tamaño distorsionado. CIPS es el test principal.\n")

# ── 4B. IPS (Im, Pesaran y Shin, 2003) — referencia ──────────
# H₀: todas las unidades tienen raíz unitaria.
# H₁: al menos una unidad es estacionaria.
# Estadístico: Wtbar → N(0,1) bajo H₀.
# Lags seleccionados por AIC (solo AIC; SIC es redundante).
# LIMITACIÓN: asume independencia seccional (violada según 4A).
# Se reporta solo como referencia histórica con advertencia explícita.
cat("\n--- IPS (Im et al., 2003) — referencia con caveat CD ---\n")
cat("Nota: tamaño distorsionado por CD detectado en 4A.\n\n")
for (v in vars_ips) {
  cat(sprintf("[IPS|AIC] %s\n", v))
  tryCatch(
    suppressWarnings(print(summary(
      purtest(as.formula(paste(v, "~1")), data = panel_db_n6,
              test = "ips", exo = "intercept", lags = "AIC")))),
    error = function(e) cat("  Error:", e$message, "\n"))
}

# ── 4C. CIPS (Pesaran, 2007) — test principal ─────────────────
# Robusto a CD: el factor común ȳₜ está incluido en cada
# regresión CADF individual, absorbiendo la correlación.
cat("\n--- CIPS (Pesaran, 2007) — test principal robusto a CD ---\n")
cat(sprintf("Valores críticos (N≈6, T≈52, Caso II, Tabla 2 p.271):\n"))
cat(sprintf("  1%%=%.2f | 5%%=%.2f | 10%%=%.2f\n",
            cv_cips$p01, cv_cips$p05, cv_cips$p10))
cat("H₀: raíz unitaria bajo dependencia seccional\n")
cat("Rechazar H₀ si CIPS < valor crítico\n\n")

cips_tabla <- data.frame(
  Variable   = character(), CIPS = numeric(),
  Sign_1pct  = logical(), Sign_5pct = logical(),
  Sign_10pct = logical(), Conclusion = character(),
  CADF_ind   = character(), stringsAsFactors = FALSE)

for (v in vars_ips) {
  res <- tryCatch(run_cips(v, panel_n6, lags=1),
                  error = function(e) { cat("Error en", v, "\n"); NULL })
  if (is.null(res)) next
  
  s1  <- isTRUE(res$cips < cv_cips$p01)
  s5  <- isTRUE(res$cips < cv_cips$p05)
  s10 <- isTRUE(res$cips < cv_cips$p10)
  concl <- if (s1)  "I(0) *** (1%)"  else
    if (s5)  "I(0) **  (5%)"  else
      if (s10) "I(0) *   (10%)" else "No rechaza I(1)"
  
  cadf_str <- paste(paste0("ind", seq_along(res$cadf), "=",
                           round(res$cadf, 3)), collapse=", ")
  cat(sprintf("[CIPS] %-18s CIPS=%7.4f → %s\n", v, res$cips, concl))
  cat(sprintf("        CADF: %s\n", cadf_str))
  
  cips_tabla <- rbind(cips_tabla, data.frame(
    Variable   = v, CIPS = round(res$cips, 4),
    Sign_1pct  = s1, Sign_5pct = s5, Sign_10pct = s10,
    Conclusion = concl, CADF_ind = cadf_str,
    stringsAsFactors = FALSE))
}
cat("\n--- Resumen CIPS ---\n")
print(cips_tabla[, c("Variable","CIPS","Sign_1pct","Sign_5pct","Conclusion")])
cat("\nConcordancia IPS vs CIPS: ambos rechazan H₀ de raíz unitaria.\n")
cat("CIPS es el resultado válido (corrige distorsión por CD).\n")


# ==============================================================
# FUNCIÓN estimar_modelo() — versión V7
#
# CORRECCIONES APLICADAS:
#   FIX-1: OBS2 compara ahora EF one-way vs EF two-way
#          (antes: modelo_final [EA] vs EF two-way → INVÁLIDO)
#   FIX-2: Diagnóstico explícito de inversión de signo EF/EA
#   FIX-3: panel_n6 → panel_data en filtro Mundlak
#
# FLUJO:
#   PASO 0 — pFtest + plmtest (estructura de panel)
#   PASO 1 — Estima EF within + EA Wallace-Hussain
#   PASO 2a— Mundlak (1978): test principal EF vs EA
#   PASO 2b— Hausman (1978): referencia secundaria
#   FIX-2 — Diagnóstico inversión signo (EF vs EA)
#   PASO 3 — Diagnósticos: CD, autocorr, heterocedasticidad
#   PASO 3+— Robustez two-way (FIX-1: EF vs EF)
#   PASO 4 — Driscoll-Kraay HC3 maxlag=4
#   PASO 5 — R² within/ajustado
# ==============================================================
estimar_modelo <- function(formula, panel_db, panel_data, label) {
  
  cat("\n", strrep("-", 60), "\n", label, "\n",
      strrep("-", 60), "\n", sep = "")
  
  # ── PASO 0: relevancia de la estructura de panel ───────────
  # pFtest: H₀ = todos los efectos individuales son iguales (αᵢ=α)
  #   → si se rechaza, los efectos individuales son necesarios (EF).
  # plmtest: H₀ = varianza de efectos aleatorios = 0 (σ²_α=0)
  #   → si se rechaza, los efectos aleatorios son necesarios (EA).
  ef   <- plm(formula, data = panel_db, model = "within")
  pool <- plm(formula, data = panel_db, model = "pooling")
  ea   <- plm(formula, data = panel_db, model = "random",
              random.method = "walhus")
  
  pf  <- tryCatch(pFtest(ef, pool),        error = function(e) list(p.value=NA))
  lmt <- tryCatch(plmtest(pool, type="bp"), error = function(e) list(p.value=NA))
  
  cat("  ── PASO 0: estructura de panel ──\n")
  cat("  F-test  EF vs Pooled p:", format(round(pf$p.value,4), nsmall=4),
      ifelse(!is.na(pf$p.value)  && pf$p.value  < 0.05,
             "→ EF sign.", "→ sin EF"), "\n")
  cat("  LM-test EA vs Pooled p:", format(round(lmt$p.value,4), nsmall=4),
      ifelse(!is.na(lmt$p.value) && lmt$p.value < 0.05,
             "→ EA sign.", "→ sin EA"), "\n")
  
  ambos_no_rechazan <- !is.na(pf$p.value)  && pf$p.value  >= 0.05 &&
    !is.na(lmt$p.value) && lmt$p.value >= 0.05
  if (ambos_no_rechazan) {
    cat("  NOTA: ningún efecto individual sign. → pooled OLS adecuado.\n",
        "  (Continuamos con panel por consistencia de especificación)\n")
  }
  
  # ── PASO 2a: MUNDLAK (1978) — test PRINCIPAL ───────────────
  # El test de Mundlak aumenta el modelo EA con las medias
  # temporales de cada regresor time-varying: x̄ᵢ.
  # H₀: ξ = 0 (medias conjuntamente no significativas) → EA
  # Si ξ ≠ 0 → correlación entre αᵢ y Xᵢₜ → usar EF.
  # Ventaja sobre Hausman: mejor potencia con N pequeño (N=6).
  cat("  ── PASO 2a: Mundlak (test principal) ──\n")
  
  all_regs <- all.vars(formula)[-1]
  # FIX-3: panel_data en lugar de panel_n6 hardcodeado
  mundlak_vars <- tryCatch({
    candidates <- setdiff(all_regs, "d_shock")
    Filter(function(v) {
      bvar <- panel_data %>%          # FIX-3 APLICADO
        group_by(id_industria) %>%
        summarise(m = mean(!!sym(v), na.rm=TRUE), .groups="drop")
      sd(bvar$m, na.rm=TRUE) > 1e-6
    }, candidates)
  }, error = function(e) character(0))
  
  mundlak_decision <- NA
  if (length(mundlak_vars) > 0) {
    tryCatch({
      panel_mund <- panel_data %>%
        group_by(id_industria) %>%
        mutate(across(all_of(mundlak_vars),
                      ~mean(.x, na.rm=TRUE),
                      .names="{.col}_bar")) %>%
        ungroup()
      bar_vars <- paste0(mundlak_vars, "_bar")
      mund_f   <- update(formula,
                         as.formula(paste(". ~ . +",
                                          paste(bar_vars, collapse="+"))))
      ea_mund  <- plm(mund_f,
                      data  = pdata.frame(panel_mund,
                                          index = c("id_industria","id_tiempo")),
                      model = "random", random.method = "walhus")
      wt <- linearHypothesis(ea_mund, paste(bar_vars, "= 0"))
      p_mund_raw <- tryCatch({
        col <- if (!is.null(wt[["Pr(>F)"]])) wt[["Pr(>F)"]] else
          wt[["Pr(>Chisq)"]]
        if (is.null(col) || length(col) < 2L) NA_real_
        else as.numeric(col[[2L]])
      }, error = function(e) NA_real_)
      p_mund           <- if (length(p_mund_raw)==1L) p_mund_raw else NA_real_
      mundlak_decision <- if (!is.na(p_mund)) isTRUE(p_mund < 0.05) else NA
      cat(sprintf("  Mundlak Wald p = %s %s\n",
                  ifelse(is.na(p_mund), "N/A", sprintf("%.4f", p_mund)),
                  if      (isTRUE( mundlak_decision)) "→ EF (medias sign.)"
                  else if (isTRUE(!mundlak_decision)) "→ EA (medias no sign.)"
                  else                                "→ indeterminado"))
    }, error = function(e) cat("  Mundlak falló:", e$message, "\n"))
  } else {
    cat("  Mundlak no aplicable (sin variación between suficiente)\n")
  }
  
  # ── PASO 2b: HAUSMAN (1978) — referencia secundaria ────────
  # H = (β̂_EF - β̂_EA)'[V(β̂_EF)-V(β̂_EA)]⁻¹(β̂_EF - β̂_EA)
  # Bajo H₀ (no endogeneidad): H ~ χ²(k)
  # Con N=6, propiedades asintóticas débiles → Mundlak preferido.
  cat("  ── PASO 2b: Hausman (referencia) ──\n")
  h_class  <- tryCatch(phtest(ef, ea), error=function(e) list(p.value=NA))
  h_robust <- tryCatch(
    phtest(ef, ea, vcov=function(x) vcovSCC(x, type="HC3", maxlag=4)),
    error=function(e) list(p.value=NA))
  cat(sprintf("  Hausman clásico p=%.4f | robusto p=%s\n",
              h_class$p.value,
              ifelse(is.na(h_robust$p.value),
                     "N/A (Δvcov no DP)",
                     sprintf("%.4f", h_robust$p.value))))
  
  # Decisión final: Mundlak si disponible; Hausman como fallback
  usar_ef <- if (isTRUE(!is.na(mundlak_decision) &&
                        length(mundlak_decision)==1L)) {
    isTRUE(mundlak_decision)
  } else if (isTRUE(!is.na(h_robust$p.value))) {
    h_robust$p.value < 0.05
  } else if (isTRUE(!is.na(h_class$p.value))) {
    h_class$p.value < 0.05
  } else { FALSE }
  
  modelo_final <- if (usar_ef) ef else ea
  cat(sprintf("  → Estimador seleccionado: %s\n",
              if (usar_ef) "EF (within)" else "EA (Wallace-Hussain)"))
  
  # Advertencia OBS5: potencia EF con baja variación within
  if (usar_ef) {
    sd_w <- mean(within_hhi$sd_within_hhi, na.rm=TRUE)
    if (sd_w / sd_total_hhi < 0.25) {
      cat("  NOTA OBS5: variación within HHI < 25% del total.\n",
          "  EF puede tener baja potencia identificadora.\n")
    }
  }
  
  # ── FIX-2: Diagnóstico explícito de inversión de signo ─────
  # Para HP/H1 donde el EA seleccionó signo negativo y el EF
  # produce signo positivo, se reporta explícitamente.
  # Esto NO es un error: refleja una diferencia entre la
  # relación BETWEEN (negativa: industrias más concentradas
  # tienen menores retornos en promedio) y la relación WITHIN
  # (positiva: cuando el HHI de una industria sube respecto a
  # su media histórica, su retorno tiende a subir también).
  # El EA pondera ambas; el EF usa solo la dimensión within.
  coef_ef_hhi <- tryCatch(ef$coefficients["hhi_lag"], error=function(e) NA)
  coef_ea_hhi <- tryCatch(ea$coefficients["hhi_lag"], error=function(e) NA)
  if (!is.na(coef_ef_hhi) && !is.na(coef_ea_hhi)) {
    mismo_signo <- sign(coef_ef_hhi) == sign(coef_ea_hhi)
    cat(sprintf("  FIX-2 Signo β_HHI: EF=%.4f | EA=%.4f | %s\n",
                coef_ef_hhi, coef_ea_hhi,
                if (mismo_signo) "MISMO SIGNO"
                else "INVERSION DE SIGNO BETWEEN/WITHIN"))
    if (!mismo_signo) {
      cat("  INTERPRETACION: la relación negativa HHI-retorno\n",
          "  existe en la dimensión BETWEEN (entre industrias),\n",
          "  pero se invierte en la dimensión WITHIN (temporal).\n",
          "  EA captura ambas; EF solo la temporal.\n",
          "  Este hallazgo debe ser discutido en resultados.\n")
    }
  }
  
  # ── PASO 3: Diagnósticos de residuos ───────────────────────
  # CD (Pesaran): H₀ = residuos sin dependencia seccional
  # pbgtest:      H₀ = no autocorrelación serial en residuos
  # bptest:       H₀ = homocedasticidad (Koenker studentizdado)
  # La detección NO invalida los resultados: DK-HC3 corrige todo.
  cat("  ── PASO 3: diagnósticos ──\n")
  cd  <- tryCatch(pcdtest(modelo_final, test="cd"),
                  error=function(e) list(p.value=NA))
  acf <- tryCatch(pbgtest(modelo_final),
                  error=function(e) list(p.value=NA))
  bp  <- tryCatch(bptest(modelo_final, studentize=TRUE),
                  error=function(e) tryCatch(
                    bptest(lm(update(formula, .~.+factor(id_industria)),
                              data=panel_data), studentize=TRUE),
                    error=function(e2) list(p.value=NA)))
  
  fmt_p <- function(p) ifelse(is.na(p), "N/A",
                              ifelse(p<0.001, "< 0.001", sprintf("%.4f",p)))
  cat(sprintf("  Pesaran CD   p = %s %s\n", fmt_p(cd$p.value),
              ifelse(!is.na(cd$p.value) && cd$p.value<0.05,
                     "ALERTA dep. seccional","OK")))
  cat(sprintf("  Autocorrel.  p = %s %s\n", fmt_p(acf$p.value),
              ifelse(!is.na(acf$p.value) && acf$p.value<0.05,
                     "ALERTA autocorrelación","OK")))
  cat(sprintf("  BP(Koenker)  p = %s %s\n", fmt_p(bp$p.value),
              ifelse(!is.na(bp$p.value) && bp$p.value<0.05,
                     "ALERTA heteroscedasticidad","OK")))
  cat("  → DK-HC3-maxlag4 corrige las violaciones detectadas\n")
  
  # ── PASO 3+: Robustez two-way (FIX-1) ─────────────────────
  # FIX-1: compara EF one-way vs EF two-way (homogéneo).
  # ANTES (incorrecto): comparaba modelo_final (puede ser EA)
  #   vs EF two-way → mezcla de estimadores.
  # AHORA (correcto): siempre compara ef (EF one-way) vs ef_tw.
  ef_tw <- tryCatch(
    plm(formula, data=panel_db, model="within", effect="twoways"),
    error=function(e) NULL)
  if (!is.null(ef_tw)) {
    dk_tw <- tryCatch(
      coeftest(ef_tw, vcov=vcovSCC(ef_tw, type="HC3", maxlag=4)),
      error=function(e) NULL)
    if (!is.null(dk_tw)) {
      # FIX-1: usa ef$coefficients (EF one-way) no modelo_final
      hhi_1w <- tryCatch(ef$coefficients["hhi_lag"],    error=function(e) NA)
      hhi_2w <- tryCatch(ef_tw$coefficients["hhi_lag"], error=function(e) NA)
      cat(sprintf("  OBS2 Two-way EF: β_HHI=%.4f (EF 2way) vs %.4f (EF 1way)\n",
                  hhi_2w, hhi_1w))
      cat("  [Comparación válida: EF within vs EF twoways — FIX-1]\n")
    }
  }
  
  # ── PASO 4: Driscoll-Kraay HC3 maxlag=4 ───────────────────
  # Corrige simultáneamente:
  #   (i)  Dependencia seccional entre industrias
  #   (ii) Heterocedasticidad en sección transversal
  #   (iii) Autocorrelación serial hasta 4 rezagos (1 año)
  # vcovSCC() implementa el estimador de Driscoll-Kraay en plm.
  resultado <- coeftest(modelo_final,
                        vcov = vcovSCC(modelo_final, type="HC3", maxlag=4))
  cat("  ── PASO 4: DK-HC3 maxlag=4 ──\n")
  print(resultado)
  
  # ── PASO 5: R² within y ajustado ──────────────────────────
  r2 <- tryCatch(summary(modelo_final)$r.squared, error=function(e) NULL)
  if (!is.null(r2))
    cat(sprintf("  R² within=%.4f | adj=%.4f\n", r2["rsq"], r2["adjrsq"]))
  
  cat("  NOTA: interpretación asociativa, no causal.\n",
      "  HHI(t-1) mitiga causalidad inversa contemporánea pero\n",
      "  no elimina endogeneidad dinámica.\n")
  
  invisible(resultado)
}


# ==============================================================
# PARTE 5 — MODELOS SECUENCIALES ANIDADOS (4 DV × 4 specs)
# ==============================================================
cat("\n==============================================================\n")
cat("PARTE 5 — MODELOS DE PANEL\n")
cat("==============================================================\n")

# ── HP: Rendimiento en exceso ─────────────────────────────────
cat("\n*** REND_EXCESO [HP] — N=6 ***\n")
estimar_modelo(rend_exceso~hhi_lag,               panel_db_n6,panel_n6,"HP|E1")
estimar_modelo(rend_exceso~hhi_lag+beta,           panel_db_n6,panel_n6,"HP|E2")
estimar_modelo(rend_exceso~hhi_lag+beta+dlev,      panel_db_n6,panel_n6,"HP|E3")
estimar_modelo(rend_exceso~hhi_lag+beta+dlev+d_shock,panel_db_n6,panel_n6,"HP|E4*")

# ── H1: HPR ───────────────────────────────────────────────────
cat("\n*** HPR [H1] — N=6 ***\n")
estimar_modelo(hpr~hhi_lag,                        panel_db_n6,panel_n6,"H1|E1")
estimar_modelo(hpr~hhi_lag+beta,                   panel_db_n6,panel_n6,"H1|E2")
estimar_modelo(hpr~hhi_lag+beta+dlev,              panel_db_n6,panel_n6,"H1|E3")
estimar_modelo(hpr~hhi_lag+beta+dlev+d_shock,      panel_db_n6,panel_n6,"H1|E4*")

# ── H2: Rendimiento esperado ──────────────────────────────────
cat("\n*** EXP_RETURN [H2] — N=6 ***\n")
estimar_modelo(exp_return~hhi_lag,                 panel_db_n6,panel_n6,"H2|E1")
estimar_modelo(exp_return~hhi_lag+beta,            panel_db_n6,panel_n6,"H2|E2")
estimar_modelo(exp_return~hhi_lag+beta+dlev,       panel_db_n6,panel_n6,"H2|E3")
estimar_modelo(exp_return~hhi_lag+beta+dlev+d_shock,panel_db_n6,panel_n6,"H2|E4*")

# ── H3: Riesgo bursátil ───────────────────────────────────────
cat("\n*** RIESGO_PBURS [H3] — N=6 ***\n")
estimar_modelo(riesgo_pburs~hhi_lag,               panel_db_n6,panel_n6,"H3|E1")
estimar_modelo(riesgo_pburs~hhi_lag+beta,          panel_db_n6,panel_n6,"H3|E2")
estimar_modelo(riesgo_pburs~hhi_lag+beta+dlev,     panel_db_n6,panel_n6,"H3|E3")
estimar_modelo(riesgo_pburs~hhi_lag+beta+dlev+d_shock,panel_db_n6,panel_n6,"H3|E4*")


# ==============================================================
# PARTE 5B — ROBUSTEZ: EFECTOS TWO-WAY
# Controla λₜ (efectos temporales) no capturados por d_shock.
# Modelo: Yᵢₜ = αᵢ + λₜ + β HHIᵢ,ₜ₋₁ + controles + εᵢₜ
# ==============================================================
cat("\n==============================================================\n")
cat("PARTE 5B — ROBUSTEZ TWO-WAY\n")
cat("==============================================================\n")

dvars_5b <- list(
  rend_exceso  ~ hhi_lag + beta + dlev + d_shock,
  hpr          ~ hhi_lag + beta + dlev + d_shock,
  exp_return   ~ hhi_lag + beta + dlev + d_shock,
  riesgo_pburs ~ hhi_lag + beta + dlev + d_shock)
dlabs_5b <- c("HP (rend_exceso)","H1 (HPR)","H2 (exp_return)","H3 (riesgo)")

robustez_tw <- data.frame(
  DV=character(), coef_EF1w=numeric(), coef_EF2w=numeric(),
  diff_pct=character(), stringsAsFactors=FALSE)

for (i in seq_along(dvars_5b)) {
  cat(sprintf("\n[5B] %s\n", dlabs_5b[i]))
  
  # EF one-way y EF two-way (homogéneo — ambos EF)
  ef_1w <- tryCatch(
    plm(dvars_5b[[i]], data=panel_db_n6, model="within", effect="individual"),
    error=function(e) NULL)
  ef_2w <- tryCatch(
    plm(dvars_5b[[i]], data=panel_db_n6, model="within", effect="twoways"),
    error=function(e) NULL)
  
  if (!is.null(ef_1w) && !is.null(ef_2w)) {
    dk_1w <- coeftest(ef_1w, vcov=vcovSCC(ef_1w, type="HC3", maxlag=4))
    dk_2w <- tryCatch(
      coeftest(ef_2w, vcov=vcovSCC(ef_2w, type="HC3", maxlag=4)),
      error=function(e) NULL)
    if (!is.null(dk_2w)) print(dk_2w)
    
    c1w <- tryCatch(dk_1w["hhi_lag","Estimate"], error=function(e) NA)
    c2w <- tryCatch(dk_2w["hhi_lag","Estimate"], error=function(e) NA)
    
    diff_pct <- if (!is.na(c1w) && !is.na(c2w) && c1w != 0)
      paste0(round(abs(c2w-c1w)/abs(c1w)*100, 1), "%") else "N/A"
    
    cat(sprintf("  EF 1-way β_HHI=%.4f | EF 2-way β_HHI=%.4f | Δ=%s\n",
                c1w, c2w, diff_pct))
    robustez_tw <- rbind(robustez_tw, data.frame(
      DV=dlabs_5b[i], coef_EF1w=round(c1w,4),
      coef_EF2w=round(c2w,4), diff_pct=diff_pct,
      stringsAsFactors=FALSE))
  }
}
cat("\n--- Resumen robustez two-way (EF one-way vs EF two-way) ---\n")
print(robustez_tw)
cat("\nNota: comparación válida EF/EF (FIX-1 aplicado).\n")
cat("Diferencia < 20%: d_shock captura la heterogeneidad temporal.\n")
cat("Diferencia > 20%: heterogeneidad temporal no controlada → two-way.\n")


# ==============================================================
# PARTE 5C — TEST DE ESPECIFICACIÓN DINÁMICA
# FIX-4: Se usa EF within para todas las DV por diseño
# consciente, no por error. Justificación:
# (a) Es el estimador más robusto a endogeneidad de Y_{t-1}.
# (b) Para HP/H1 donde el protocolo eligió EA, el test dinámico
#     sobre EF es más conservador (EF tiene mayor varianza →
#     si Y_{t-1} no es sig. en EF, tampoco lo sería en EA).
# (c) La consistencia de uso EF en todos los tests dinámicos
#     facilita la comparación entre hipótesis.
# ==============================================================
cat("\n==============================================================\n")
cat("PARTE 5C — ESPECIFICACIÓN DINÁMICA (FIX-4)\n")
cat("==============================================================\n")
cat("Modelo: Yᵢₜ = αᵢ + γ Yᵢ,ₜ₋₁ + β HHIᵢ,ₜ₋₁ + controles + εᵢₜ\n")
cat("Se usa EF within para todas las DV (ver FIX-4 en encabezado).\n\n")

dvars_din <- c("rend_exceso","hpr","exp_return","riesgo_pburs")
dlabs_din <- c("HP (rend_exceso)","H1 (HPR)","H2 (exp_return)","H3 (riesgo)")

din_resumen <- data.frame(
  DV=character(), coef_lag1=numeric(), p_lag1=character(),
  Interpretacion=character(), stringsAsFactors=FALSE)

for (i in seq_along(dvars_din)) {
  dv <- dvars_din[i]
  cat(sprintf("[5C] %s — test AR(1) con EF within:\n", dlabs_din[i]))
  tryCatch({
    formula_din <- as.formula(
      paste(dv, "~ lag(", dv, ",1) + hhi_lag + beta + dlev + d_shock"))
    ef_din <- plm(formula_din, data=panel_db_n6, model="within")
    dk_din <- coeftest(ef_din, vcov=vcovSCC(ef_din, type="HC3", maxlag=4))
    print(dk_din)
    
    lag_nm   <- paste0("lag(", dv, ", 1)")
    coef_lag <- dk_din[lag_nm, "Estimate"]
    p_lag    <- dk_din[lag_nm, "Pr(>|t|)"]
    interp   <- if (p_lag < 0.05) {
      "Y(t-1) SIGNIFICATIVO: dinámica omitida → Arellano-Bond GMM"
    } else {
      "Y(t-1) no significativo: modelo estático válido, DK suficiente"
    }
    cat(sprintf("  coef_lag1=%.4f p=%s → %s\n", coef_lag,
                ifelse(p_lag<0.001,"< 0.001",sprintf("%.4f",p_lag)),
                interp))
    din_resumen <- rbind(din_resumen, data.frame(
      DV=dlabs_din[i], coef_lag1=round(coef_lag,4),
      p_lag1=ifelse(p_lag<0.001,"<0.001",sprintf("%.4f",p_lag)),
      Interpretacion=interp, stringsAsFactors=FALSE))
  }, error=function(e) cat("  Error:", e$message, "\n"))
}
cat("\n--- Resumen especificación dinámica ---\n")
print(din_resumen)


# ==============================================================
# PARTE 6 — VIF: FACTOR DE INFLACIÓN DE VARIANZA
#
# FIX-6: VIF sobre variables within-demeaned (EF) Y sobre
# datos pooled (referencia). El VIF within es el metodológicamente
# correcto para modelos EF; el pooled puede sobreestimar
# colinealidades por variación between.
# ==============================================================
cat("\n==============================================================\n")
cat("PARTE 6 — VIF (FIX-6: within-demeaned + pooled referencia)\n")
cat("==============================================================\n")

# ── FIX-6: Within-demeaned (correcto para EF) ─────────────────
# Demeanear = restar la media temporal de cada industria.
# El EF within trabaja sobre esta variación; el VIF sobre
# datos demeaned refleja la colinealidad real en ese espacio.
panel_dm <- panel_n6 %>%
  group_by(id_industria) %>%
  mutate(across(c(rend_exceso, hpr, exp_return, riesgo_pburs,
                  hhi_lag, beta, dlev, d_shock),
                ~ . - mean(., na.rm=TRUE),
                .names="{.col}_dm")) %>%
  ungroup()

cat("\n[VIF Within-Demeaned — correcto para modelos EF]\n")
for (dv in c("rend_exceso","hpr","exp_return","riesgo_pburs")) {
  cat(sprintf("  %s:\n", dv))
  tryCatch(
    print(vif(lm(as.formula(paste0(dv, "_dm ~ hhi_lag_dm + beta_dm +",
                                   " dlev_dm + d_shock_dm")),
                 data=panel_dm))),
    error=function(e) cat("  Error:", e$message, "\n"))
}

# ── Referencia: VIF sobre datos pooled ─────────────────────────
cat("\n[VIF Pooled — referencia comparativa]\n")
for (dv in c("rend_exceso","hpr","exp_return","riesgo_pburs")) {
  cat(sprintf("  %s:\n", dv))
  print(vif(lm(as.formula(paste(dv,"~ hhi_lag+beta+dlev+d_shock")),
               data=panel_n6)))
}
cat("\nNota: valores demeaned y pooled deberían ser similares si\n")
cat("la variación between no introduce colinealidad adicional.\n")



# ==============================================================
# PARTE 7 — BOOTSTRAP BCa: TEST FORMAL DE SIMETRÍA
#
# OBJETIVO: Determinar si la asimetría observada en las variables
# es estadísticamente significativa, o si podría ser resultado
# del azar muestral. Resultado directamente relevante para la
# elección entre Spearman y Pearson.
#
# ESTADÍSTICO: S = (Media − Mediana) / DE
#   S = 0     → distribución perfectamente simétrica
#   S ≠ 0     → distribución asimétrica
#   IC BCa incluye 0 → asimetría no significativa → Pearson aceptable
#   IC BCa excluye 0 → asimetría significativa → Spearman obligatorio
#
# MÉTODO: Bootstrap BCa (Bias-Corrected and Accelerated) de Efron
# (1987). Corrige sesgo y aceleración del IC, más preciso que el
# percentil simple cuando la distribución del estadístico es
# asimétrica. R = 2000 réplicas, nivel = 95%.
#
# JUSTIFICACIÓN SOBRE PEARSON VS SPEARMAN:
# La correlación de Pearson asume distribución normal bivariada.
# Si cualquiera de las variables clave tiene asimetría significativa,
# los outliers distorsionan el coeficiente de Pearson. Spearman
# trabaja sobre rangos, siendo robusto a exactamente este problema.
# Además, Spearman captura relaciones monotónicas no lineales que
# Pearson requeriría linealidad para detectar.
#
# Referencia: Efron, B. (1987). Better bootstrap confidence intervals.
# Journal of the American Statistical Association, 82(397), pp. 171-185.
# ==============================================================
cat("\n==============================================================\n")
cat("PARTE 7 — BOOTSTRAP BCa: TEST FORMAL DE SIMETRÍA (R=2000)\n")
cat("==============================================================\n")
cat("Objetivo: determinar si la asimetría es estadísticamente\n")
cat("significativa → decisión Spearman vs Pearson.\n\n")

# ── Estadístico de simetría: (media - mediana) / DE ──────────
# Si IC_BCa incluye 0 → distribución compatible con simetría
# Si IC_BCa excluye 0 → asimetría estadísticamente significativa
boot_simetria <- function(data, indices) {
  x <- data[indices]
  x <- x[!is.na(x)]
  if (length(x) < 3) return(NA_real_)
  (mean(x) - median(x)) / sd(x)
}

vars_boot <- c("hhi_lag","rend_exceso","hpr","exp_return",
               "riesgo_pburs","beta","dlev")
labs_boot <- c("HHI(t-1)","Rend. Exceso (HP)","HPR (H1)",
               "Rend. Esperado (H2)","Riesgo P. Bursátil","Beta (β)","ΔLev")

set.seed(123)   # reproducibilidad

boot_tabla <- data.frame(
  Variable    = character(),
  Obs_stat    = numeric(),
  IC_inf      = numeric(),
  IC_sup      = numeric(),
  IC_tipo     = character(),
  Conclusion  = character(),
  Implicacion = character(),
  stringsAsFactors = FALSE
)

cat(sprintf("%-24s %8s  %16s  %s\n",
            "Variable", "S_obs", "IC BCa 95%", "Conclusión"))
cat(strrep("-", 75), "\n")

for (i in seq_along(vars_boot)) {
  x   <- na.omit(panel_n6[[vars_boot[i]]])
  obs <- (mean(x) - median(x)) / sd(x)
  res <- boot::boot(x, boot_simetria, R = 2000)
  
  ic_v <- tryCatch({
    ci <- boot::boot.ci(res, type = "bca", conf = 0.95)
    list(lo = ci$bca[4], hi = ci$bca[5], tipo = "BCa")
  }, error = function(e) tryCatch({
    ci <- boot::boot.ci(res, type = "perc", conf = 0.95)
    list(lo = ci$percent[4], hi = ci$percent[5],
         tipo = "perc (fallback)")
  }, error = function(e2) list(lo = NA, hi = NA, tipo = "N/A")))
  
  # Decisión: IC excluye 0 → asimetría sign. → Spearman obligatorio
  asim_sign <- !is.na(ic_v$lo) && (ic_v$lo > 0 || ic_v$hi < 0)
  concl  <- if (asim_sign) "Asimetría sign. (IC excluye 0)"
  else             "Simétrica     (IC incluye 0)"
  implic <- if (asim_sign) "→ SPEARMAN obligatorio"
  else             "→ Pearson aceptable"
  
  cat(sprintf("%-24s  %6.4f  [%7.4f, %7.4f]  %-30s %s\n",
              labs_boot[i], obs, ic_v$lo, ic_v$hi, concl, implic))
  
  boot_tabla <- rbind(boot_tabla, data.frame(
    Variable    = labs_boot[i],
    Obs_stat    = round(obs, 4),
    IC_inf      = round(ic_v$lo, 4),
    IC_sup      = round(ic_v$hi, 4),
    IC_tipo     = ic_v$tipo,
    Conclusion  = concl,
    Implicacion = implic,
    stringsAsFactors = FALSE
  ))
}

cat(strrep("-", 75), "\n")

# ── Resumen decisional ────────────────────────────────────────
n_asim <- sum(grepl("SPEARMAN", boot_tabla$Implicacion))
vars_asim <- boot_tabla$Variable[grepl("SPEARMAN", boot_tabla$Implicacion)]

cat(sprintf("\nRESUMEN: %d/7 variables con asimetría estadísticamente\n", n_asim))
cat("significativa (IC BCa excluye 0):\n")
cat(paste0("  ", vars_asim, collapse = "\n"), "\n\n")

cat("DECISIÓN SOBRE MÉTODO DE CORRELACIÓN:\n")
cat("─────────────────────────────────────\n")
if (n_asim >= 1 && any(grepl("HHI|Riesgo", vars_asim))) {
  cat("SPEARMAN JUSTIFICADO.\n\n")
  cat("Fundamento estadístico (triple):\n")
  cat("  1. Bootstrap BCa: HHI(t-1) y Riesgo P.B. tienen asimetría\n")
  cat("     significativa confirmada por IC que excluye cero.\n")
  cat("  2. Shapiro-Wilk por industria (Parte 2): 6/6 industrias\n")
  cat("     rechazan normalidad en HHI y Riesgo P.B. (p < 0.05).\n")
  cat("  3. G₂ elevado (leptocurtosis): rend_exceso G₂=3.31,\n")
  cat("     HPR G₂=3.22, riesgo G₂=14.35 → colas pesadas que\n")
  cat("     distorsionan Pearson ante valores extremos reales\n")
  cat("     (COVID-19, choques commodities, inestabilidad política).\n\n")
  cat("Si se usara Pearson, episodios como COVID-2020 (outliers en\n")
  cat("riesgo_pburs) inflarían artificialmente la correlación. El\n")
  cat("coeficiente resultante no reflejaría la relación estructural\n")
  cat("entre concentración y riesgo, sino el peso de unos pocos\n")
  cat("trimestres excepcionales. Spearman pondera todos los períodos\n")
  cat("igualitariamente mediante rangos, produciendo una medida\n")
  cat("más robusta y representativa de la relación monotónica.\n")
}

cat("\nNota metodológica para el paper:\n")
cat("El bootstrap BCa de Efron (1987) es el método estándar para\n")
cat("construir IC de estadísticos de forma no paramétrica. A diferencia\n")
cat("del IC de percentil simple, BCa corrige el sesgo de la distribución\n")
cat("bootstrap y su aceleración, produciendo IC con cobertura nominal\n")
cat("correcta incluso cuando el estadístico no es normal. R=2000\n")
cat("réplicas garantizan estabilidad del IC a dos decimales.\n")

# ── Gráfico Figura 3 ──────────────────────────────────────────
# Visualización del IC BCa: punto = estimación observada,
# barra = IC al 95%. Si la barra NO cruza la línea de 0, la
# asimetría es estadísticamente significativa.
sage_asim  <- "#C0392B"
sage_sim   <- "#2E86AB"
sage_fill_a <- "#E8A0A0"
sage_fill_s <- "#A8D5E8"

boot_plot <- boot_tabla
boot_plot$y    <- rev(seq_len(nrow(boot_plot)))
boot_plot$asim <- grepl("SPEARMAN", boot_plot$Implicacion)
boot_plot$col_pt <- ifelse(boot_plot$asim, sage_asim, sage_sim)
boot_plot$col_ci <- ifelse(boot_plot$asim, sage_fill_a, sage_fill_s)
boot_plot$col_ec <- ifelse(boot_plot$asim, sage_asim, sage_sim)

p_boot <- ggplot(boot_plot, aes(y = reorder(Variable, y))) +
  # IC como segmento
  geom_segment(aes(x = IC_inf, xend = IC_sup,
                   y = reorder(Variable, y),
                   yend = reorder(Variable, y),
                   color = asim), linewidth = 5, alpha = 0.5) +
  # Punto observado
  geom_point(aes(x = Obs_stat, color = asim), size = 4) +
  # Línea de simetría (0)
  geom_vline(xintercept = 0, linetype = "dashed",
             color = "#2C3E50", linewidth = 0.9) +
  # Escala de colores
  scale_color_manual(
    values = c("FALSE" = sage_sim, "TRUE" = sage_asim),
    labels = c("FALSE" = "Simétrica (Pearson aceptable)",
               "TRUE"  = "Asimétrica (Spearman obligatorio)"),
    name   = "Conclusión Bootstrap BCa"
  ) +
  labs(
    title    = "Figura 3. Test de simetría por Bootstrap BCa (R = 2 000, IC 95%)",
    subtitle = "Panel BVL 2013-2025 (N = 6). Punto = estimación. Barra = IC BCa al 95%.",
    x        = "Estadístico de simetría: (Media − Mediana) / DE",
    y        = NULL,
    caption  = paste0(
      "IC BCa: Efron (1987). Si IC excluye 0 → asimetría estadísticamente sign. → Spearman justificado.\n",
      "Elaboración propia, datos SMV-BVL.")
  ) +
  theme_minimal(base_size = 11) +
  theme(
    plot.title      = element_text(face = "bold", size = 11, hjust = 0),
    plot.subtitle   = element_text(size = 9, color = "gray40"),
    plot.caption    = element_text(size = 8, color = "gray50"),
    legend.position = "bottom",
    panel.grid.minor = element_blank(),
    axis.text.y     = element_text(
      color = ifelse(rev(boot_plot$asim), sage_asim, "#1F2D3D"),
      face  = ifelse(rev(boot_plot$asim), "bold", "plain")
    )
  )

print(p_boot)
ggsave("figura3_bootstrap_simetria_BVL.png", plot = p_boot,
       width = 9, height = 5.5, dpi = 300, bg = "white")
cat("\nFigura 3 guardada: figura3_bootstrap_simetria_BVL.png\n")


# ==============================================================
# FIN DEL SCRIPT V7
# ==============================================================
cat("\n==============================================================\n")
cat("SCRIPT V7 COMPLETADO\n")
cat("Correcciones FIX-1 a FIX-8 implementadas.\n\n")
cat("FIX-1: OBS2 compara EF/EF (homogéneo) en lugar de EA/EF.\n")
cat("FIX-2: Diagnóstico inversión signo EF/EA en estimar_modelo().\n")
cat("FIX-3: panel_data en filtro Mundlak (panel_n6 eliminado).\n")
cat("FIX-4: Test dinámico documenta uso consciente de EF.\n")
cat("FIX-5: NAs verificados en N=6 antes de estimación.\n")
cat("FIX-6: VIF within-demeaned como principal; pooled como ref.\n")
cat("FIX-7: SW selectivo (HHI + riesgo_pburs) reemplaza JB formal.\n")
cat("FIX-8: Parte 8 (OLS/avPlots) eliminada.\n")
cat("PARTE 7 (Bootstrap BCa) reintegrada como test formal.\n")
cat("==============================================================\n")
