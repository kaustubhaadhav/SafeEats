# SafeEats Risk Model Documentation

## Overview

SafeEats uses a **deterministic, rule-based system** to classify ingredient risks. This document explains how risk levels are assigned, how conflicts between data sources are resolved, and the scientific basis for each classification.

## Risk Levels

SafeEats uses five risk levels, ranging from safe to critical:

| Level | Value | Color | Description |
|-------|-------|-------|-------------|
| **Safe** | 0 | Green (#22C55E) | No known carcinogenic concerns |
| **Low** | 1 | Lime (#84CC16) | Minor concerns with limited evidence |
| **Moderate** | 2 | Amber (#F59E0B) | Possible carcinogen or health concern |
| **High** | 3 | Orange (#F97316) | Probable carcinogen or significant concern |
| **Critical** | 4 | Red (#EF4444) | Known carcinogen to humans |

## Data Sources

### 1. IARC (International Agency for Research on Cancer)

The IARC is part of the World Health Organization and provides the most authoritative carcinogen classifications:

| IARC Group | Description | SafeEats Risk Level |
|------------|-------------|---------------------|
| Group 1 | Carcinogenic to humans | **Critical** |
| Group 2A | Probably carcinogenic to humans | **High** |
| Group 2B | Possibly carcinogenic to humans | **Moderate** |
| Group 3 | Not classifiable as carcinogenic | **Low** |

### 2. California Proposition 65

California's Safe Drinking Water and Toxic Enforcement Act of 1986 maintains a list of chemicals known to cause cancer or reproductive harm:

| Prop 65 Classification | SafeEats Risk Level |
|------------------------|---------------------|
| Known carcinogen | **High** |
| Reproductive toxicant | **Moderate** |

## Conflict Resolution

When an ingredient is classified by both IARC and Prop 65, we use the following priority order:

```
IARC Group 1 (100) > IARC Group 2A (90) > IARC Group 2B (80) > Prop 65 (70) > IARC Group 3 (60)
```

**Principle**: IARC classifications take precedence because they represent international scientific consensus based on comprehensive evidence reviews.

### Example: Aspartame

- **IARC**: Group 2B (possibly carcinogenic) - classified July 2023
- **Prop 65**: Listed as possible concern
- **SafeEats**: Uses IARC Group 2B → **Moderate** risk

## Classification Rules

### Critical Risk (IARC Group 1)

These substances are **known to cause cancer in humans** based on sufficient evidence:

| Ingredient | Notes |
|------------|-------|
| Processed meat | Hot dogs, bacon, sausages - IARC 2015 |
| Alcohol / Ethanol | In alcoholic beverages - causes multiple cancers |

### High Risk (IARC Group 2A or significant concern)

These substances are **probably carcinogenic to humans**:

| Ingredient | Source | Notes |
|------------|--------|-------|
| Acrylamide | IARC 2A | Forms in fried/baked starchy foods |
| Red meat | IARC 2A | Unprocessed mammalian muscle meat |
| Sodium nitrite | IARC 2A | Preservative that forms nitrosamines |
| Glyphosate | IARC 2A | Herbicide residue in some grains |
| Erythrosine | Prop 65 | Red Dye No. 3 - thyroid concerns |
| Titanium dioxide | IARC 2B* | Banned in EU (elevated due to regulatory action) |

*Note: Titanium dioxide is IARC Group 2B but elevated to High due to EU ban.

### Moderate Risk (IARC Group 2B or health concerns)

These substances are **possibly carcinogenic** or have health concerns:

| Ingredient | Source | Notes |
|------------|--------|-------|
| Aspartame | IARC 2B | Artificial sweetener - classified 2023 |
| BHA (Butylated hydroxyanisole) | IARC 2B | Antioxidant preservative |
| Caramel color | Prop 65 | 4-MEI in certain caramel colors |
| Monosodium glutamate | Prop 65 | MSG - some sensitivity concerns |
| Sodium benzoate | Prop 65 | Can form benzene with vitamin C |
| Potassium bromate | IARC 2B | Flour improver - banned in EU |

### Low Risk (IARC Group 3 or minimal concern)

These substances have **limited evidence** of carcinogenicity:

| Ingredient | Notes |
|------------|-------|
| Allura red (Red 40) | IARC Group 3 - not classifiable |
| Tartrazine (Yellow 5) | IARC Group 3 - may cause allergies |
| Sucralose | No IARC classification - some concerns |
| Citric acid | Natural compound - generally safe |

### Safe (No classification)

Ingredients with no evidence of carcinogenic or toxicological concern:

- Water
- Salt (sodium chloride)
- Sugar
- Common vitamins and minerals
- Most natural plant ingredients

## Overall Risk Calculation

The overall risk for a product is the **maximum risk level** of any individual ingredient:

```
Overall Risk = MAX(ingredient_1_risk, ingredient_2_risk, ..., ingredient_n_risk)
```

**Example**:
- Product contains: water (safe), sugar (safe), aspartame (moderate), sodium nitrite (high)
- Overall risk = **High** (highest individual risk)

## Ingredient Normalization

Before risk assessment, ingredients are normalized to canonical names:

1. **E-numbers** → Chemical names (e.g., E621 → monosodium glutamate)
2. **Aliases** → Canonical names (e.g., MSG → monosodium glutamate)
3. **Variations** → Standard form (e.g., BHA → butylated hydroxyanisole)

This ensures consistent matching regardless of how ingredients are labeled.

## Versioning

Risk rules are versioned using semantic versioning:

- **Major version**: Significant methodology changes
- **Minor version**: New ingredients or source additions
- **Patch version**: Rule corrections or clarifications

Current version: `1.0.0` (December 2024)

## Limitations

1. **Not exhaustive**: The database doesn't cover all possible ingredients
2. **Context matters**: Dose, exposure duration, and individual factors affect actual risk
3. **Evolving science**: Classifications may change as new research emerges
4. **Processing effects**: Some carcinogens form during cooking (not in raw ingredients)
5. **Trace amounts**: Detection doesn't indicate harmful levels

## Disclaimer

This risk model is for **informational and educational purposes only**. It is not a substitute for professional medical advice. The presence of an ingredient with a risk classification does not mean a product will cause cancer—many factors affect actual health outcomes.

Always consult healthcare professionals for medical concerns.

## References

- [IARC Monographs](https://monographs.iarc.who.int/)
- [California Proposition 65](https://oehha.ca.gov/proposition-65)
- [Open Food Facts](https://world.openfoodfacts.org/)