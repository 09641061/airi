# Validación Empírica, Diseño Experimental y Checklist de Calidad

Directrices para seleccionar métodos de validación, formular métricas pre/post test y verificar la conformidad antes de la entrega.

## 1. Metodologías de Validación en Ingeniería Aplicada

1. **Estudio de Caso Real (Pre-Test vs. Post-Test):**
   - Implementado en una unidad productiva u organización (ej. MYPE o empresa).
   - Compara indicadores del estado inicial ($T_0$) frente al estado final post-implementación ($T_1$).
2. **Simulación Computacional:**
   - Métodos Monte Carlo, Simulación de Eventos Discretos o Hardware-in-the-Loop bajo condiciones dinámicas y estocásticas.
3. **Benchmarking y Experimentación Comparativa:**
   - Comparación empírica directa del modelo propuesto frente a algoritmos del estado del arte utilizando datasets públicos estandarizados (Kaggle, UCI, IEEE).
4. **Juicio de Expertos:**
   - Evaluación por panel de especialistas mediante rúbricas cuantitativas con coeficientes de concordancia (V de Aiken o W de Kendall).

---

## 2. Lista de Verificación y Control de Calidad

Antes de enviar cualquier entregable de tesis (TB1, TP1, TB2, TB3, DD1, TF1) o manuscrito de artículo, verificar:

### Metadatos y Título
- [ ] Título sigue la fórmula: Aporte + Problema + Contexto + Técnica ($<20$ palabras).
- [ ] Filiaciones institucionales y códigos ORCID completos.

### Introducción
- [ ] Contexto sustentado con estadísticas de fuentes oficiales internacionales/nacionales.
- [ ] Problema e impactos cuantificados (\$, %, horas hombre).
- [ ] Breve Estado del Arte sintetiza $\\ge 5$ artículos Q1/Q2 recientes.
- [ ] Motivación justifica la brecha de conocimiento (*Research Gap*).
- [ ] Objetivos específicos siguen la secuencia: Diagnosticar $\\rightarrow$ Diseñar $\\rightarrow$ Implementar $\\rightarrow$ Validar.

### Estado del Arte (RSL)
- [ ] Ecuación booleana de Scopus/WoS documentada con operadores y filtros.
- [ ] Embudo de exclusión de 4 pasos detallado con cantidades de artículos.
- [ ] 30 artículos centrales seleccionados ($\\ge 80\\%$ Q1/Q2).
- [ ] Síntesis presentada en uno de los 4 formatos formales (texto continuo, tabla síntesis, matriz de componentes, matriz de características).
- [ ] Conclusiones identifican vacíos y justifican la propuesta de la tesis.

### Diseño del Aporte
- [ ] Marco en 5 pasos (P1–P5) completado.
- [ ] Diagrama de arquitectura claro con entradas, componentes, flujos y salidas.
- [ ] Formalización matemática o algorítmica para cada componente.
- [ ] Estrategia de novedad claramente identificada (Hibridación, Transferencia, Optimización, Nuevo Componente, Poda).

### Citas, Conectores y Turnitin
- [ ] Párrafos redactados bajo la fórmula de 5 pasos (Tópico + Evidencia + Conector + Análisis + Brecha).
- [ ] Puntuación de conectores aplicada correctamente (coma post-conector inicial; punto y coma con coma en oraciones compuestas).
- [ ] Normas APA 7ma edición en todo el texto (autor-año en texto; lista de referencias completa con DOI al final).
- [ ] Traducciones de artículos en inglés tratadas como paráfrasis (sin comillas ni "traducción propia").
- [ ] Similitud de texto Turnitin $\\le 10\\%$ (Tesis) / $\\le 7\\%$ (Artículo); Turnitin IA $\\le 25\\%$.
