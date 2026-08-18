# Code by WENDY A.TORRENS 
# Analyses for manuscript:
# Title: Perturbed sensory memory associated with schizotypy symptom load
# Journal: Schizophrenia Research 

# REVISIONS #2 ANALYSES 10/2025

# clear environment
rm(list = ls())

# Libraries
library(lme4)
library(lmerTest)
library(tidyverse)
library(tidyr)
library(stats)
library(dplyr)
library(ggplot2)
library(effectsize)
library(stats)
library(readxl)
library(patchwork)
library(QuantPsyc)
library(readxl)

# Load data file
d <- read_excel("/Your/Path/Analyses_09_29/MMN_N1_SPQ.xlsx")

# CREATED VARIABLES ------------------------------------------------------------
# This step is not necessary. However, creating variables allows for not having
# to link to dataset in every formula

CP <- d$Cognitive_Perceptual
IP <-d$Interpersonal
DIS <-d$Disorganized
SPQ <-d$Total_Score

# CREATED VARIABLES ------------------------------------------------------------
# Factores
CP <- d$Cognitive_Perceptual
IP <-d$Interpersonal
DIS <-d$Disorganized
SPQ <-d$Total_Score

# ERPs
mmn_m_amp <- d$MMN_M_Amplitude # average of 31 and 32
mmn_m_lat <- d$MMN_M_Latency 

n1_std_m_amp <- d$N1_M_Std_Amplitude
n1_std_m_lat <- d$N1_M_Std_Latency

n1_dev_m_amp <- d$N1_M_Dev_Amplitude
n1_dev_m_lat <- d$N1_M_Dev_Latency

#-------------------- Demographics ---------------------------------------------
High <- dem%>%
  filter(Status == "High")

Control <- dem%>%
  filter(Status == "Control")

t.test(High$Age, Control$Age, paired = F)
t.test(High$GPA, Control$GPA, paired = F)
t.test(High$`Raven's Score`, Control$`Raven's Score`, paired = F)

# Include the group label to each dataset
High$Group <- "High"
Control$Group <- "Control"

# Combine 
df <- rbind(High, Control)

# Create a contingency table
tab <- table(df$Group, df$Handedness)
tab

chisq.test(tab)

#-------------------- M-Regression Amplitude Analyses --------------------------
# Function for model summary and effect size
run_lm <- function(formula, data, label) {
  model <- lm(formula, data = data)
  summary_model <- summary(model)
  r_sq <- summary_model$r.squared
  cohen_f <- r_sq / (1 - r_sq)
  
  cat("\n", strrep("-", 60), "\n")
  cat("Model:", label, "\n")
  print(summary_model$coefficients)
  cat("R² =", round(r_sq, 3), " | Cohen's f² =", round(cohen_f, 3), "\n")
  
  list(model = model,
       summary = summary_model,
       r_sq = r_sq,
       cohen_f = cohen_f)
}

# Run amplitude regressions
factor_n1_std_m <- run_lm(n1_std_m_amp ~ DIS + IP + CP, d, "N1 Standard Amplitude")
factor_n1_dev_m <- run_lm(n1_dev_m_amp ~ DIS + IP + CP, d, "N1 Deviant Amplitude")
factor_mmn_m    <- run_lm(mmn_m_amp ~ DIS + IP + CP, d, "MMN Amplitude")

# Compute standardized beta for deviant model (significant effect)
beta_model10 <- lm.beta(factor_n1_dev_m$model)
print(beta_model10)

#-------------------- Plot Relationships (Amplitude) ---------------------------

# Data in repeated measures format
d_long <- d %>%
  pivot_longer(
    cols = c(Cognitive_Perceptual, Interpersonal, Disorganized),
    names_to = "Trait",
    values_to = "Trait_Value"
  )

# Colors and theme 
trait_colors <- c(
  "Cognitive_Perceptual" = "darkgrey",
  "Interpersonal" = "lightgrey",
  "Disorganized" = "black"
)

base_theme <- theme_classic(base_size = 15) +
  theme(
    axis.text = element_text(color = "black"),
    legend.title = element_text(size = 12),
    legend.text = element_text(size = 12)
  )

# Function for trait relationship plots
plot_trait <- function(y_var, title, y_label) {
  ggplot(d_long, aes(x = Trait_Value, y = .data[[y_var]], color = Trait)) +
    geom_point(size = 2) +
    geom_smooth(method = "lm", se = FALSE, fullrange = TRUE, size = 2) +
    scale_color_manual(values = trait_colors) +
    labs(title = title, x = "Factors", y = y_label) +
    base_theme +
    coord_cartesian(ylim = c(-12, 8))
}

# Generate plots
set.seed(123)
fig_std_n1 <- plot_trait("N1_M_Std_Amplitude", "Standard N100", "Standard N100 Amplitude (µV)")
fig_dev_n1 <- plot_trait("N1_M_Dev_Amplitude", "Deviant N100", "Deviant N100 Amplitude (µV)")
fig_mmn    <- plot_trait("MMN_M_Amplitude",    "MMN",           "MMN Amplitude (µV)")

# Remove legends for aesthetic preference
fig_std_n1_nolegend <- fig_std_n1 + theme(legend.position = "none")
fig_dev_n1_nolegend <- fig_dev_n1 + theme(legend.position = "none")
fig_mmn_nolegend    <- fig_mmn    + theme(legend.position = "none")

# Combine plots 
factor_scatter <- fig_std_n1_nolegend + fig_dev_n1_nolegend + fig_mmn_nolegend
factor_scatter

#-- Plot Latency------------------------------------
d_long <- d %>%
  pivot_longer(cols = c(Cognitive_Perceptual, Interpersonal, Disorganized),
               names_to = "Trait", values_to = "Trait_Value")

set.seed(123)  
fig_std_n1 <- ggplot(d_long, aes(x = Trait_Value, y = N1_M_Std_Latency, color = Trait)) +
  geom_point(size = 2) + 
  geom_smooth(method = "lm", se = FALSE, fullrange = TRUE, size = 2) +  
  scale_color_manual(values = c("Cognitive_Perceptual" = "darkgrey", 
                                "Interpersonal" = "lightgrey", 
                                "Disorganized" = "black")) + 
  labs(title = "Standard N100", x = "Factors", y = "Standard N100 Latency (µV)") +
  theme_classic() +
  theme(
    text = element_text(size = 15),
    axis.title = element_blank(),  
    axis.text = element_text(color = "black"),
    legend.title = element_text(size = 11),
    legend.text = element_text(size = 11),
    legend.position = "none"
  )+
  coord_cartesian(ylim = c(80, 180))
fig_std_n1


set.seed(123)  
fig_dev_n1 <- ggplot(d_long, aes(x = Trait_Value, y = N1_M_Dev_Latency, color = Trait)) +
  geom_point(size = 2) + 
  geom_smooth(method = "lm", se = FALSE, fullrange = TRUE, size = 2) +  
  scale_color_manual(values = c("Cognitive_Perceptual" = "darkgrey", 
                                "Interpersonal" = "lightgrey", 
                                "Disorganized" = "black")) +  
  labs(title = "Deviant N100", x = "Factors", y = "Deviant N100 Latency (µV)") +
  theme_classic() +
  theme(
    text = element_text(size = 15),
    axis.title = element_blank(),  # <-- fixed here
    axis.text = element_text(color = "black"),
    legend.title = element_text(size = 11),
    legend.text = element_text(size = 11),
    legend.position = "none"
  )+
  coord_cartesian(ylim = c(80, 180))
fig_dev_n1


set.seed(123)  
fig_mmn <- ggplot(d_long, aes(x = Trait_Value, y = MMN_M_Latency, color = Trait)) +
  geom_point(size = 2) + 
  geom_smooth(method = "lm", se = FALSE, fullrange = TRUE, size = 2) +  
  scale_color_manual(values = c("Cognitive_Perceptual" = "darkgrey", 
                                "Interpersonal" = "lightgrey", 
                                "Disorganized" = "black")) +  
  labs(title = "MMN", x = "Factors", y = "MMN Latency (µV)") +
  theme_classic() +
  theme(
    text = element_text(size = 15),
    axis.title = element_blank(),  # <-- fixed here
    axis.text = element_text(color = "black"),
    legend.title = element_text(size = 11),
    legend.text = element_text(size = 11),
  )+
  coord_cartesian(ylim = c(145,250))
fig_mmn


factor_scatter <- fig_std_n1 + fig_dev_n1 + fig_mmn

# Show it
factor_scatter


#-------------------- M-Regression Latency Analyses ----------------------------
# Function for model summary and effect size (includes p-value)
run_lm <- function(formula, data, label) {
  model <- lm(formula, data = data)
  summary_model <- summary(model)
  r_sq <- summary_model$r.squared
  cohen_f <- r_sq / (1 - r_sq)
  p_val <- pf(summary_model$fstatistic[1],
              summary_model$fstatistic[2],
              summary_model$fstatistic[3],
              lower.tail = FALSE)
  
  cat("\n", strrep("-", 60), "\n")
  cat("Model:", label, "\n")
  print(summary_model$coefficients)
  cat("R² =", round(r_sq, 3),
      "| Cohen's f² =", round(cohen_f, 3),
      "| Model p =", signif(p_val, 3), "\n")
  
  list(model = model,
       summary = summary_model,
       r_sq = r_sq,
       cohen_f = cohen_f,
       p_val = p_val)
}

factor_n1_std_m_lat <- run_lm(n1_std_m_lat ~ DIS + IP + CP, d, "N1 Standard Latency")
factor_n1_dev_m_lat <- run_lm(n1_dev_m_lat ~ DIS + IP + CP, d, "N1 Deviant Latency")
factor_mmn_m_lat    <- run_lm(mmn_m_lat ~ DIS + IP + CP, d, "MMN Latency")

#- MANOVA FOR COMPONENTS AND GROUPS (sz + controls) Amplitude and Latency ------
# ANALYSES ORIGINAL ERPs
summary(man_model <- manova(cbind(n1_std_m_amp, n1_dev_m_amp, mmn_m_amp, n1_std_m_lat, n1_dev_m_lat, mmn_m_lat) ~ Group, data = d))
eta_squared(man_model)
summary.aov(man_model)

# ------------------- Total Scores and Factors ----------------------------

dis_spq <- ggplot(d, aes(x = DIS, y = Total_Score)) +
  geom_point(size = 2, color = "black") + 
  geom_smooth(method =lm, se = FALSE, fullrange = TRUE, size = 2, color = "grey") +  
  labs(x = "Disorganized", y = "Total SPQ Scores") +
  theme_classic() +
  theme(
    text = element_text(size = 20),
    axis.title = element_text(color = "black"),
    axis.text = element_text(color = "black"),
    legend.title = element_text(size = 14),
    legend.text = element_text(size = 12)
  )
dis_spq

ip_spq <- ggplot(d, aes(x = IP, y = Total_Score)) +
  geom_point(size = 2, color = "black") + 
  geom_smooth(method =lm, se = FALSE, fullrange = TRUE, size = 2, color = "grey") +  
  labs(x = "Interpersonal", y = "Total SPQ Scores") +
  theme_classic() +
  theme(
    text = element_text(size = 20),
    axis.title = element_text(color = "black"),
    axis.text = element_text(color = "black"),
    legend.title = element_text(size = 14),
    legend.text = element_text(size = 12)
  )
ip_spq
#---------------------Supplemental Analyses ------------------------------------
# Corr test electrodes 

cor.test(d$N1_Fz_Std_Amplitude, d$N1_Cz_Std_Amplitude)
0.9650898^2 #R-squared 

cor.test(d$N1_Fz_Dev_Amplitude, d$N1_Cz_Dev_Amplitude)
0.9534512^2 

cor.test(d$MMN_Fz_Amplitude, d$MMN_Cz_Amplitude)
0.8428225^2 

# Ravens, GPA, and component amplitudes and latencies 

# high MMN with Intelligence estimates
mmn_amp_high_int <- summary(model <- lm(MMN_M_Amplitude ~ Raven_Score + GPA, data = high))
# effect size
r_sq_mmn_amp_high_int <- mmn_amp_high_int$r.squared
print(Cohen_f_mmn_amp_high_int <- r_sq_mmn_amp_high_int / (1 - r_sq_mmn_amp_high_int))

# control MMN with Intelligence estimates
mmn_amp_control_int <- summary(model_iq_control_mmn <- lm(MMN_M_Amplitude ~ Raven_Score + GPA, data = control))
r_sq_mmn_amp_control_int <- mmn_amp_control_int$r.squared
print(Cohen_f_mmn_amp_control_int <- r_sq_mmn_amp_control_int / (1 - r_sq_mmn_amp_control_int))

# high stand. N1  with Intelligence estimates
std_n1_avg_high_int <- summary(model_iq_high_std <- lm(N1_M_Std_Amplitude ~ Raven_Score + GPA, data = high))
r_sq_std_n1_avg_high_int <- std_n1_avg_high_int$r.squared
print(Cohen_f_std_n1_avg_high_int <- r_sq_std_n1_avg_high_int / (1 - r_sq_std_n1_avg_high_int))

# control stand. N1  with Intelligence estimates
std_n1_avg_control_int <- summary(model_iq_control_std <- lm(N1_M_Std_Amplitude ~ Raven_Score + GPA, data = control))
r_sq_std_n1_avg_control_int <- std_n1_avg_control_int$r.squared
print(Cohen_f_std_n1_avg_control_int <- r_sq_std_n1_avg_control_int / (1 - r_sq_std_n1_avg_control_int))

# high deviant N1  with Intelligence estimates
dev_n1_avg_high_int <- summary(model_iq_high_dev <- lm(N1_M_Dev_Amplitude ~ Raven_Score + GPA, data = high))
r_sq_dev_n1_avg_high_int <- dev_n1_avg_high_int$r.squared
print(Cohen_f_dev_n1_avg_high_int <- r_sq_dev_n1_avg_high_int / (1 - r_sq_dev_n1_avg_high_int))

# control deviant N1  with Intelligence estimates
dev_n1_avg_control_int <- summary(model_iq_control_dev <- lm(N1_M_Dev_Amplitude ~ Raven_Score + GPA, data = control))
r_sq_dev_n1_avg_control_int <- dev_n1_avg_control_int$r.squared
print(Cohen_f_dev_n1_avg_control_int <- r_sq_dev_n1_avg_control_int / (1 - r_sq_dev_n1_avg_control_int))
max(SPQ)

# Latency at mean of both Fz and Cz & IQ ------------------------------------- 

# Mean of both Fz and Cz

# high MMN with Intelligence estimates
mmn_lat_high_int <- summary(model <- lm(MMN_M_Latency ~ Raven_Score + GPA, data = high))
# effect size
r_sq_mmn_lat_high_int <- mmn_lat_high_int$r.squared
print(Cohen_f_mmn_lat_high_int <- r_sq_mmn_lat_high_int / (1 - r_sq_mmn_lat_high_int))
# control MMN with Intelligence estimates
mmn_lat_control_int <- summary(model_iq_control_mmn <- lm(MMN_M_Latency ~ Raven_Score + GPA, data = control))
r_sq_mmn_lat_control_int <- mmn_lat_control_int$r.squared
print(Cohen_f_mmn_lat_control_int <- r_sq_mmn_lat_control_int / (1 - r_sq_mmn_lat_control_int))

# high stand. N1  with Intelligence estimates
std_n1_lat_high_int <- summary(model_iq_high_std <- lm(N1_M_Std_Latency ~ Raven_Score + GPA, data = high))
r_sq_std_n1_lat_high_int <- std_n1_lat_high_int$r.squared
print(Cohen_f_std_n1_lat_high_int <- r_sq_std_n1_lat_high_int / (1 - r_sq_std_n1_lat_high_int))
# control stand. N1  with Intelligence estimates
std_n1_lat_control_int <- summary(model_iq_control_std <- lm(N1_M_Std_Latency ~ Raven_Score + GPA, data = control))
r_sq_std_n1_lat_control_int <- std_n1_lat_control_int$r.squared
print(Cohen_f_std_n1_lat_control_int <- r_sq_std_n1_lat_control_int / (1 - r_sq_std_n1_lat_control_int))

# high deviant N1  with Intelligence estimates
dev_n1_lat_high_int <- summary(model_iq_high_dev <- lm(N1_M_Dev_Latency ~ Raven_Score + GPA, data = high))
r_sq_dev_n1_lat_high_int <- dev_n1_lat_high_int$r.squared
print(Cohen_f_dev_n1_lat_high_int <- r_sq_dev_n1_lat_high_int / (1 - r_sq_dev_n1_lat_high_int))
# control deviant N1  with Intelligence estimates
dev_n1_lat_control_int <- summary(model_iq_control_dev <- lm(N1_M_Dev_Latency ~ Raven_Score + GPA, data = control))
r_sq_dev_n1_lat_control_int <- dev_n1_lat_control_int$r.squared
print(Cohen_f_dev_n1_lat_control_int <- r_sq_dev_n1_lat_control_int / (1 - r_sq_dev_n1_lat_control_int))
max(SPQ)


