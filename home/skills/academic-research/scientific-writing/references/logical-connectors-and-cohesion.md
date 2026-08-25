# Conectores Lógicos, Marcadores Discursivos y Cohesión de Párrafos

Los conectores lógicos establecen vínculos semánticos, sintácticos y argumentativos entre oraciones y párrafos en la redacción científica.

## 1. Clasificación Funcional de Conectores Lógicos

| Categoría Funcional | Función en el Texto Científico | Conectores Recomendados (Español / Inglés) | Ejemplo Aplicado |
| :--- | :--- | :--- | :--- |
| **Causa / Justificación** | Introduce el origen, motivo o premisa técnica de un fenómeno o decisión. | *debido a que, puesto que, ya que, dado que, a causa de, en vista de que* / *due to, since, as, given that* | *El rendimiento mejoró notablemente, **debido a que** se integró una etapa previa de filtrado adaptativo.* |
| **Consecuencia / Efecto** | Expresa el resultado, inferencia o producto derivado de una acción previa. | *por lo tanto, por consiguiente, en consecuencia, de ahí que, por ende, así pues* / *therefore, consequently, hence, thus* | *Los datos presentaron un severo desbalance; **por consiguiente,** se aplicó la técnica de sobremuestreo SMOTE.* |
| **Contraste / Oposición** | Confronta dos enfoques, resalta limitaciones o matiza postulados previos. | *sin embargo, no obstante, en contraste, a pesar de, empero, mientras que* / *however, nevertheless, in contrast, whereas* | *Varios autores emplean redes densas; **sin embargo,** estas carecen de mecanismos de explicabilidad.* |
| **Adición / Acumulación** | Agrega evidencia complementaria o argumentos concurrentes de otros autores. | *asimismo, además, por otra parte, del mismo modo, igualmente, sumado a ello* / *furthermore, moreover, additionally, likewise* | *El modelo reduce la latencia de respuesta; **asimismo,** optimiza el consumo energético en nodos IoT.* |
| **Orden / Secuencia** | Organiza cronológica o procedimentalmente las fases metodológicas. | *en primer lugar, posteriormente, a continuación, finalmente, previamente* / *firstly, subsequently, thereafter, finally* | ***En primer lugar,** se filtraron los datos atípicos; **posteriormente,** se entrenó el clasificador.* |
| **Énfasis / Explicación** | Puntualiza, reformula o precisa un concepto técnico clave. | *es decir, en otras palabras, esto es, cabe destacar, es preciso señalar* / *namely, that is to say, specifically, notably* | *El sistema opera en tiempo real; **es decir,** procesa cada fotograma con una latencia menor a 30 ms.* |
| **Ejemplificación** | Concreta abstracciones teóricas mediante herramientas, algoritmos o casos. | *por ejemplo, a modo de ilustración, tal como, como es el caso de, verbigracia* / *for instance, for example, such as* | *Existen arquitecturas ligeras para visión por computador, **tal como** MobileNetV3 y ShuffleNet.* |
| **Conclusión / Síntesis** | Cierra una sección, sintetiza hallazgos o formula deducciones integrales. | *en síntesis, en resumen, en suma, de lo expuesto se concluye, en definitiva* / *in summary, to conclude, in short* | ***En síntesis,** la literatura analizada evidencia una brecha en validaciones en entornos industriales reales.* |
| **Comparación** | Contrasta desempeños, arquitecturas o métricas entre diferentes enfoques. | *a diferencia de, en comparación con, de igual manera, similarmente, paralelamente* / *unlike, compared with, similarly* | ***A diferencia de** los métodos tradicionales, la propuesta integra aprendizaje por refuerzo adaptativo.* |
| **Condición / Restricción** | Establece supuestos operacionales o restricciones técnicas de validez. | *siempre que, a condición de que, en caso de que, con tal de que, si y solo si* / *provided that, on condition that, if and only if* | *El algoritmo converge de forma estable **siempre que** la tasa de aprendizaje se mantenga decreciente.* |

---

## 2. Reglas Sintácticas y de Puntuación

1. **Conector al Inicio de Oración:** Todo conector oracional (de contraste, consecuencia o adición) que encabeza una oración debe ir seguido obligatoriamente de una coma:
   - ✅ *Correcto:* `Por lo tanto, la hipótesis nula fue rechazada con un nivel de significancia de 0.05.`
   - ❌ *Incorrecto:* `Por lo tanto la hipótesis nula fue rechazada con un nivel de significancia de 0.05.`
2. **Proposiciones Independientes Compuestas:** Cuando un conector enlaza dos oraciones independientes completas, debe ir precedido por punto y coma (o punto y seguido) y sucedido por coma:
   - **Estructura:** `[Proposición 1]; [Conector], [Proposición 2].`
   - ✅ *Correcto:* `El modelo base alcanzó alta precisión; sin embargo, requirió una sobrecarga computacional prohibitiva para dispositivos embebidos.`
3. **Conectores Continuativos Cortos:** Nexos explicativos o causales directos (*porque, puesto que, ya que*) no se separan con coma posterior:
   - ✅ *Correcto:* `No fue posible evaluar el modelo en producción porque la muestra disponible carecía de variabilidad térmica.`

---

## 3. Vicios Comunes y Anti-Patrones a Evitar

- **Pleonasmos conectivos:** Evitar duplicaciones como *"mas sin embargo"*, *"pero sin embargo"*, *"empero más sin embargo"*. Usar únicamente un conector (*"sin embargo"* o *"no obstante"*).
- **Muletillas y lenguaje coloquial:** No usar expresiones como *"bueno"*, *"entonces"* reiterativo, *"en base a"* (lo correcto es *sobre la base de* o *con base en*) ni *"por otro lado"* sin un *"por un lado"* precedente.
- **Estilo telegráfico (ausencia de conectores):** La yuxtaposición excesiva de oraciones cortas rompe la fluidez argumentativa.

---

## 4. Fórmula de Construcción de Párrafos Académicos en 5 Pasos

Todo párrafo argumentativo en la Introducción, Estado del Arte, Metodología o Discusión debe seguir la estructura:

$$\\text{Párrafo} = [\\text{Idea Tópica}] + [\\text{Evidencia Empírica / Citas}] + [\\text{Conector Lógico}] + [\\text{Análisis Crítico / Métricas}] + [\\text{Transición / Brecha}]$$

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ 1. IDEA TÓPICA (Premisa central del párrafo):                               │
│    Introduce el eje temático, técnico o problema específico.                │
│ 2. EVIDENCIA CIENTÍFICA (Citas narrativas/parentéticas):                    │
│    Sustenta con autores representativos del estado del arte reciente.       │
│ 3. CONECTOR LÓGICO DE ENLACE:                                               │
│    Introduce la comparación, contraste o relación de consecuencia.          │
│ 4. ANÁLISIS CRÍTICO Y VALIDACIÓN:                                           │
│    Detalla técnica, entorno experimental y métricas numéricas obtenidas.    │
│ 5. TRANSICIÓN O IDENTIFICACIÓN DE BRECHA (Research Gap):                    │
│    Conecta la limitación hallada con la propuesta de investigación propia.  │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Ejemplo de Párrafo Construido con la Fórmula:

> **[Idea Tópica]** La detección automatizada de anomalías en redes de distribución eléctrica representa un desafío crítico para la continuidad del suministro de energía. **[Evidencia Científica]** En este contexto, diversos estudios han implementado clasificadores basados en árboles de decisión y redes neuronales convolucionales (Gómez & Ramírez, 2023; Zhang et al., 2024). **[Conector Lógico]** Sin embargo, **[Análisis Crítico]** mientras que Gómez y Ramírez lograron una sensibilidad del 94.2% en entornos sintéticos, el modelo experimentó una degradación del 18% al someterse a perturbaciones de ruido en alimentadores reales. **[Transición / Brecha]** Esta limitación evidencia la necesidad de incorporar mecanismos de filtrado adaptativo en tiempo real, aspecto central que fundamenta el desarrollo del aporte propuesto en esta investigación.
