# Revisión Sistemática de Literatura (RSL / SLR) y Matrices de Síntesis

Metodología para conducir revisiones sistemáticas en Scopus y Web of Science, seleccionar 30 artículos primarios (Q1/Q2) y estructurar matrices de síntesis.

## 1. Protocolo de Búsqueda y Selección en Scopus / Web of Science

### 1.1 Ecuación de Búsqueda Booleana (Search String)
$$\\text{Search String} = ([\\text{Términos del Problema}]) \\text{ AND } ([\\text{Términos de Enfoques/Factores}]) \\text{ AND } ([\\text{Términos de Técnicas/Tecnologías}])$$

- **Sintaxis en Scopus:**
  `TITLE-ABS-KEY ((synonym1 OR synonym2) AND (factor1 OR factor2) AND (tech1 OR tech2))`
- **Filtros Obligatorios:**
  * Tipo de documento: *Article* (Revistas científicas).
  * Periodo: Últimos 3 a 5 años (2022–2026).
  * Cuartiles: **Q1 / Q2** en Scimago Journal Rank (SJR) o JCR ($\\ge 80\\%$ de la muestra).

### 1.2 Embudo de Exclusión en 4 Pasos
1. **Paso 1 (Filtro por Título):** Se descartan artículos fuera del ámbito temático del problema.
2. **Paso 2 (Filtro por Resumen / Abstract):** Se eliminan estudios puramente descriptivos que no aporten soluciones metodológicas o algoritmos.
3. **Paso 3 (Filtro por Introducción y Conclusiones):** Se descartan trabajos sin métricas cuantitativas o validaciones empíricas.
4. **Paso 4 (Lectura a Texto Completo):** Se consolidan los **30 artículos centrales** definitivos.

---

## 2. Resúmenes de Artículos en la Tesis (Capítulo 2.2)

Los 30 artículos deben organizarse en **2 a 4 categorías temáticas** (ej. *2.2.1 Modelos basados en Visión Artificial*, *2.2.2 Arquitecturas basadas en Edge Computing*).

Cada artículo se resume en un párrafo de 50 a 100 palabras aplicando la fórmula:
$$\\text{Resumen} = [\\text{Aporte del Autor}] + [\\text{Técnicas y Componentes Empleados}] + [\\text{Entorno de Aplicación}] + [\\text{Forma de Validación}] + [\\text{Resultados Cuantitativos}]$$

---

## 3. Las 4 Formas de Presentación de la Síntesis en el Artículo Científico

```
                            FORMAS DE PRESENTACIÓN DE SÍNTESIS
                                            │
        ┌───────────────────┬───────────────┴───────────────┬───────────────────┐
        ▼                   ▼                               ▼                   ▼
     Forma 1             Forma 2                         Forma 3             Forma 4
 Texto Continuo     Tabla de Síntesis             Tabla de Componentes  Tabla de Características
(Agrupado por       (Ref + Síntesis 2-4           (Filas: Aportes;      (Filas: Aportes;
 Ejes Temáticos)     líneas: Aporte+Val+Res)       Cols: Componentes)    Cols: Parámetros/Técnicas)
```

### Forma 1: Texto Continuo Agrupado Temáticamente
Párrafos densos y comparativos organizados por subsecciones conceptuales usando la fórmula de párrafos en 5 pasos.

### Forma 2: Tabla de Síntesis de Artículos
| # | Nombre del Aporte / Sistema | Descripción (Aporte + Método de Validación + Resultados Cuantitativos) | Referencia APA |
|---|---|---|---|
| 1 | DeepEdge-Anomaly | Red neuronal convolucional en Raspberry Pi 4; validado en sistema IEEE 14-bus; alcanzó 98.2% F1-score con 24ms de latencia. | Zhang et al. (2023) |

### Forma 3: Matriz de Componentes del Dominio
| Referencia | Ingesta de Datos | Preprocesamiento / Filtro | Motor de Inferencia | Visualización / Alertas |
| :--- | :---: | :---: | :---: | :---: |
| Gómez & Ramírez (2023) | IoT MQTT | Filtro de Kalman | Random Forest | Panel Web |
| Zhang et al. (2024) | API REST | Transformada Wavelet | MobileNetV3 | Notificación Push |
| **Aporte Propuesto** | **MQTT + Kafka** | **Wavelet Adaptativo** | **CNN-LSTM Híbrido** | **Web en Tiempo Real + SMS** |

### Forma 4: Matriz Comparativa de Características Técnicas
| Autor y Año | Técnica | Dataset / Escenario | Tamaño de Muestra | Precisión / F1 | Latencia | Limitaciones |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| Chen et al. (2022) | SVM + RBF | Microred sintética | 10,000 muestras | 92.4% | 150 ms | Alto tiempo de entrenamiento |
| Patel & Lee (2024) | Transformer | Alimentador industrial real | 45,000 muestras | 97.8% | 85 ms | Requiere GPU dedicada |

---

## 4. Redacción de Conclusiones de la Revisión de Literatura (Capítulo 2.3)

La conclusión del estado del arte debe responder formalmente 5 preguntas en un párrafo integrador:
1. ¿Cuáles son los tipos de aportes y arquitecturas predominantes en la literatura?
2. ¿Cuáles son las técnicas y algoritmos más utilizados?
3. ¿Cómo valida la mayoría de autores (casos de estudio, simulaciones, experimentos) y qué métricas alcanzan?
4. ¿Cuáles son las brechas no resueltas (*Research Gaps*), sesgos o limitaciones persistentes?
5. ¿De qué manera los vacíos identificados justifican directamente el desarrollo de la presente investigación?
