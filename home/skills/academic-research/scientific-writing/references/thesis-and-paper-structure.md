# Estructura Comparativa: Plan de Tesis vs. Artículo Científico

Guía comparativa entre la estructura formal del Plan de Tesis de Pregrado y el Artículo Científico para revistas indexadas (IEEE Transactions / Elsevier / Scopus Q1/Q2).

## 1. Alineación Estructural Global

| Componente | Plan de Tesis de Pregrado | Artículo Científico (IEEE / Scopus) |
| :--- | :--- | :--- |
| **Identificación** | Carátula formal con Facultad, Título, Autores (ORCID), Asesor Temático y Asesor Metodológico (ORCID), Ciudad y Fecha. | Encabezado con Título, Autores con afiliación institucional completa, correos y Corresponding Author (*). |
| **Preliminares** | Resumen (máx 250 palabras) + Abstract en inglés + Índices de contenido, tablas y figuras. | Abstract (220 - 250 palabras) + Keywords (4 a 6 términos técnicos normalizados). |
| **Capítulo / Sec. 1** | **Capítulo I: Introducción** (Contexto, Problema, Importancia, Breve Estado del Arte, Motivación, Objetivos, Organización). | **1. Introduction** (Contexto socioeconómico, Problema técnico, Estado del Arte, Motivación/Brecha, Novedad, Propósito, Contribuciones A/B/C, Organización). |
| **Capítulo / Sec. 2** | **Capítulo II: Revisión de la Literatura** (Desarrollo: búsqueda Scopus/WoS, selección de 30 papers; Análisis taxonómico; Conclusiones y brechas). | **2. Literature Review / Related Work** (Descripción del dominio, síntesis de 30 papers en 1 de 4 formatos, Conclusiones del Estado del Arte). |
| **Capítulo / Sec. 3** | **Capítulo III: Diseño del Aporte** (Aporte General, diagrama de arquitectura, proceso y detalle de componentes C1..Ck con ecuaciones/algoritmos). | **3. Proposed Contribution / Design** (Diagrama de arquitectura, flujo de procesamiento, formalización matemática/algorítmica). |
| **Capítulos Posteriores** | Cap. IV: Artefacto; Cap. V: Validación; Cap. VI: Conclusiones y Trabajos Futuros; Anexos MYPE (SIPOC, Ishikawa, datos). | Sec. 4: Implementation; Sec. 5: Validation & Experiments; Sec. 6: Discussion & Conclusion. |

---

## 2. Fórmula de Construcción del Título de Investigación

El título debe sintetizar la investigación en **1 a 2 líneas** (máximo 15-20 palabras) bajo la estructura:

$$\\text{Título} = [\\text{Aporte / Contribución}] + \\text{" para "} + [\\text{Problema a Resolver}] + \\text{" en "} + [\\text{Contexto / Escenario}] + \\text{" mediante "} + [\\text{Técnica (Opcional)}]$$

### Ejemplos Validados:
- *Con Técnica Específica:* `Metodología de detección de fallas en turbinas de gas basada en redes neuronales recurrentes LSTM.`
- *Con Escenario Empresarial:* `Sistema de gestión de inventarios para la reducción de quiebres de stock en microempresas del sector retail textil peruano mediante algoritmos de predicción temporal.`

---

## 3. Redacción Paso a Paso del Capítulo I / Sección 1 (Introducción)

La Introducción debe estructurarse mediante 8 bloques indispensables:

1. **Contexto del Problema y su Importancia (1–2 párrafos):**
   - Presentar el sector o fenómeno macroeconómico / tecnológico.
   - Respaldar con estadísticas de fuentes de alto impacto (INEI, Banco Mundial, CEPAL, IEEE).
2. **Problema e Importancia del Problema (1–2 párrafos):**
   - Detallar el mecanismo técnico de la falla o ineficiencia operativa.
   - Cuantificar pérdidas económicas (\$), sobrecostos o tasas de error.
3. **Breve Estado del Arte (1 párrafo):**
   - Síntesis agrupada de ~5 artículos relevantes de los últimos 3-5 años (Q1/Q2).
4. **Motivación (Brecha de Conocimiento / Research Gap) (1 párrafo):**
   - Crítica constructiva al estado del arte general: ¿por qué las soluciones existentes fallan o son insuficientes en el contexto objetivo?
5. **Novedad y su Justificación (1 párrafo):**
   - Elemento innovador propuesto y sustento lógico de por qué resolverá la limitación detectada.
6. **Propósito / Objetivos (1 párrafo):**
   - **Objetivo General (OG):**
     $$\\text{OG} = \\text{[Verbo Infinitivo]} + \\text{[Aporte]} + \\text{" basado en "} + \\text{[Técnica]} + \\text{" para "} + \\text{[Problema]} + \\text{" con la finalidad de "} + \\text{[Métrica/Impacto]}$$
   - **Objetivos Específicos (Secuencia Científica Obligatoria):**
     * **OE1 (Diagnóstico/Revisión):** *Analizar / Identificar* los requerimientos, factores críticos y el estado del arte.
     * **OE2.A (Diseño):** *Diseñar / Modelar* la arquitectura conceptual, matemática y lógica del aporte.
     * **OE2.B (Construcción):** *Desarrollar / Implementar* el artefacto o prototipo funcional.
     * **OE3 (Validación):** *Evaluar / Validar* el desempeño del aporte mediante [Caso de estudio/Simulación/Experimento], verificando las mejoras en [Métricas].
7. **Principales Contribuciones (Viñetas A, B, C):**
   - Entregables tangibles: (a) Modelo teórico, (b) Prototipo software/hardware, (c) Protocolo/Dataset de validación.
8. **Organización del Documento (1 párrafo):**
   - Breve descripción del contenido de cada capítulo/sección subsiguiente.
