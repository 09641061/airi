# Diseño del Aporte, Taxonomía de Artefactos y Formulación de la Novedad

Metodología para diseñar, formalizar y redactar el Capítulo III de Tesis o la Sección 3 del Artículo Científico.

## 1. El Marco de Diseño en 5 Pasos (P1–P5)

```
  [P1. Conceptualización] ──> [P2. Bosquejo Arquitectural] ──> [P3. Motivación] ──> [P4. Novedad] ──> [P5. Diseño Final]
   (Q1: Definición              (Actores, Procesos,             (Crítica al        (5 Estrategias      (Bosquejo Base +
    Q2: Finalidad                Componentes, Flujos)            Estado del Arte)   de Innovación)      Novedad Integrada)
    Q3: Componentes
    Q4: Evaluación)
```

### Paso 1 (P1): Conceptualización (4 Preguntas Fundamentales)
- **Q1 (Definición):** ¿Qué es el aporte? (*Modelo, método, framework, arquitectura algorítmica*).
- **Q2 (Finalidad):** ¿Cuál es su propósito esencial? (*Qué problema resuelve y qué beneficio genera*).
- **Q3 (Componentes):** ¿Qué módulos funcionales lo integran? (*Derivados de la matriz de componentes de la literatura*).
- **Q4 (Evaluación):** ¿Cómo se evaluará y con qué métricas cuantitativas objetivas?

### Paso 2 (P2): Bosquejo Arquitectural del Aporte
Diagrama formal que incluye:
1. **Actores / Stakeholders:** Roles humanos o sistemas externos que interactúan.
2. **Componentes de Proceso y Decisión:** Cajas de funciones y rombos de bifurcación.
3. **Flujos de Información:** Flechas orientadas que indican la dirección de datos.
4. **Elementos de Persistencia:** Bases de datos (cilindros), archivos y reportes.

### Paso 3 (P3): Motivación
Explicación fundamentada de por qué las arquitecturas actuales de la literatura fallan o resultan insuficientes en el contexto objetivo.

### Paso 4 (P4): Las 5 Estrategias de Novedad
1. **Hibridación / Combinación:** Integrar dos técnicas consolidadas para sumar fortalezas (ej. Algoritmo Genético + CNN).
2. **Adaptación Transdisciplinar:** Transferir una metodología exitosa de otra área al problema de estudio.
3. **Mejora Algorítmica / Técnica:** Modificar funciones de pérdida, capas o heurísticas para reducir latencia o consumo.
4. **Incorporación de un Nuevo Componente:** Añadir un módulo no contemplado en la literatura (ej. explicabilidad XAI en tiempo real).
5. **Simplificación / Eliminación de Redundancias:** Diseñar una arquitectura ligera y de bajo costo para despliegue en microcontroladores o dispositivos Edge.

### Paso 5 (P5): Diseño Final del Aporte
$$\\text{Diseño Final del Aporte} = \\text{Bosquejo Base (P2)} + \\text{Novedad Incorporada (P4)}$$

---

## 2. Jerarquía Epistemológica de Artefactos de Investigación

| Tipo de Artefacto | Nivel de Abstracción | Pregunta que Responde | Entregable de Ingeniería |
| :--- | :--- | :--- | :--- |
| **Teoría** | Epistemológico | *¿Por qué ocurre el fenómeno?* | Modelo de relaciones causales. |
| **Constructo** | Conceptual | *¿Qué concepto estamos midiendo?* | Conjunto de variables e indicadores. |
| **Modelo** | Teórico-Analítico | *¿Cómo se comporta el sistema?* | Modelo matemático, bayesiano o de estados. |
| **Método** | Procedimental | *¿Cómo se ejecuta el proceso paso a paso?* | Metodología operacional en fases. |
| **Herramienta** | Operacional | *¿Con qué instrumento se realiza?* | Software, API, script ejecutable o circuito. |
| **Instancia** | Empírico-Aplicado | *¿Funciona en un entorno real?* | Implementación piloto en una empresa. |

---

## 3. Redacción del Capítulo III (Tesis) y Sección 3 (Artículo)

1. **3.1 Aporte General:**
   - Párrafo declarando concepto, finalidad, fundamentos teóricos y listado de componentes.
   - Figura de arquitectura en bloques con alta nitidez.
   - Explicación del flujo de procesamiento paso a paso (Entrada $\\rightarrow$ Procesamiento $\\rightarrow$ Salida).
   - Justificación rigurosa de la novedad.
2. **3.2 a 3.k Detalle de Componentes ($C_1 \\dots C_k$):**
   - Entradas (*Inputs*): Esquemas de datos, señales o parámetros.
   - Lógica de Procesamiento: Ecuaciones matemáticas, pseudocódigo o algoritmos aplicados.
   - Salidas (*Outputs*): Vectores, estados o resultados intermedios.
