---
name: agile-requirements-upc
description: Especificar y auditar requisitos de software bajo el estándar académico de la Universidad Peruana de Ciencias Aplicadas (UPC). Cubre las **3 Cs** y criterios **INVEST** para Historias de Usuario, redacción de criterios de aceptación en Gherkin (BDD) con las reglas estrictas UPC (prohibición de imperativos, conjunciones y causalidades en títulos; redacción en tercera persona), especificación de Requisitos Funcionales bajo el formato A-R-O y los 7 atributos de calidad (atómico, completo, consistente, trazable, priorizado, verificable, único), modelado UML de Casos de Uso (actores, precondiciones, flujo básico, flujos alternativos con regla de oro de referenciación por nombre de paso), y especificación cuantitativa de Requisitos No Funcionales según ISO/IEC 25010 con escenarios de calidad SEI (Source–Stimulus–Artifact–Environment–Response–Response Measure). Usar siempre que se redacten historias de usuario, se definan criterios de aceptación BDD, se elabore un documento de especificación de requisitos (SRS), se modelen casos de uso UML, o se audite la calidad de requisitos funcionales y no funcionales.
---

# Especificación de Requisitos Ágiles bajo Estándar UPC

Esta skill cubre **única y exclusivamente** la ingeniería de requisitos de software con enfoque ágil y tradicional. **No** cubre citación académica (usar `apa7-citation`) ni redacción científica de tesis (usar `scientific-writing`).

## Dominios Cubiertos

1. **Historias de Usuario y BDD:** Las **3 Cs** (Card, Conversation, Confirmation), criterios **INVEST** (Independent, Negotiable, Valuable, Estimable, Small, Testable) y redacción de criterios de aceptación en Gherkin (*Given–When–Then*).
2. **Requisitos Funcionales:** Formato A-R-O (*Action–Result–Object*), 7 atributos de calidad de un requisito (atómico, completo, consistente, trazable, priorizado, verificable, ID único) y trazabilidad bidireccional con reglas de negocio (BRD).
3. **Casos de Uso UML:** Especificación formal con actores primarios/secundarios, precondiciones, flujo básico numerado y flujos alternativos con regla de oro de referenciación por **nombre de paso** (nunca por número).
4. **Requisitos No Funcionales / ISO 25010:** Modelo de calidad de 8 categorías (adecuación funcional, eficiencia de desempeño, compatibilidad, usabilidad, fiabilidad, seguridad, mantenibilidad, portabilidad) con redacción cuantitativa obligatoria (prohibición absoluta de adjetivos subjetivos como *"rápido"*, *"seguro"*, *"amigable"*).
5. **Escenarios de Calidad SEI:** Estructura de 6 partes (*Source–Stimulus–Artifact–Environment–Response–Response Measure*) para formalizar y probar atributos de calidad en el diseño arquitectónico.

## Reglas Principales

1. **Viabilidad de Historia de Usuario:** Toda US en el *Product Backlog* debe satisfacer los seis criterios INVEST. Si algún criterio falla, la historia **no está Ready** y debe reformularse.
2. **Prohibición de Imperativos en Títulos Gherkin:** Nunca usar `Verify`, `Assert`, `Should`, `Verificar`, `Validar` o `Debería` en el título del escenario. Los títulos describen el caso de negocio.
3. **Prohibición de Conjunciones en Títulos:** `and`, `or`, `but`, `y`, `o`, `pero` en el título de un escenario indican que el flujo debe dividirse en escenarios atómicos independientes.
4. **Prohibición de Causalidades en Títulos:** Excluir `because`, `since`, `so`, `para`, `debido a` — el valor funcional ya reside en la plantilla de la Historia de Usuario.
5. **Redacción en Tercera Persona:** Todos los pasos del escenario se redactan impersonalmente (*"El cliente ingresa"*, *"El sistema muestra"*). Nunca primera persona (*"Yo ingreso"*, *"Cuando hago clic"*).
6. **Regla de Oro de Casos de Uso:** Los flujos alternativos referencian pasos del flujo básico **únicamente por su nombre** (ej. `Al inicio de VALIDAR_IDENTIDAD...`), nunca por número correlativo. Esto evita la rotura de enlaces al insertar nuevos pasos.
7. **Cuantificación Obligatoria de RNF:** Todo requisito no funcional debe sustituir adjetivos subjetivos por métricas numéricas exactas (latencias en ms, disponibilidades en %, tamaños en MB) y mapearse explícitamente a una subcaracterística de ISO/IEC 25010.
8. **Trazabilidad Bidireccional:** Cada requisito funcional se asocia a una regla de negocio (BRD) o necesidad del *stakeholder* mediante un ID único (`REQ-FN-001`, `REQ-NF-001`, `UC-REG-01`).

## Build Order

Sigue este flujo al especificar o auditar los requisitos de un producto de software.

| # | Fase | Foco Principal | Archivo de Referencia |
|---|---|---|---|
| 1 | Historias de Usuario | 3 Cs de Ron Jeffries, criterios INVEST, formato *Como–Quiero–Para* | [references/user-stories-and-invest.md](references/user-stories-and-invest.md) |
| 2 | Criterios de Aceptación BDD | Sintaxis Gherkin, reglas estrictas de títulos (sin imperativos/conjunciones/causalidades), tercera persona | [references/user-stories-and-invest.md](references/user-stories-and-invest.md) |
| 3 | Requisitos Funcionales | Fórmula A-R-O, 7 atributos de calidad, codificación única, priorización MoSCoW/Numérica | [references/functional-requirements-and-use-cases.md](references/functional-requirements-and-use-cases.md) |
| 4 | Casos de Uso UML | Actores primario/secundario, precondiciones, flujo básico, flujos alternativos por nombre de paso | [references/functional-requirements-and-use-cases.md](references/functional-requirements-and-use-cases.md) |
| 5 | Requisitos No Funcionales | Taxonomía ISO/IEC 25010, plantilla US-RNF, prohibición de adjetivos subjetivos | [references/quality-attributes-and-iso25010.md](references/quality-attributes-and-iso25010.md) |
| 6 | Escenarios de Calidad SEI | 6 partes (Source–Stimulus–Artifact–Environment–Response–Response Measure) | [references/quality-attributes-and-iso25010.md](references/quality-attributes-and-iso25010.md) |