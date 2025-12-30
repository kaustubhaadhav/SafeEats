# SafeEats Data Sources

This document describes all data sources used by SafeEats, their characteristics, and important limitations.

## Primary Data Sources

### 1. Open Food Facts API

**URL**: https://world.openfoodfacts.org

**Purpose**: Product information and ingredient lists

**Type**: Open-source, community-maintained database

#### What We Use
- Product name and brand
- Ingredient list (text)
- Product images
- Barcode associations

#### API Endpoint
```
GET https://world.openfoodfacts.org/api/v2/product/{barcode}.json
```

#### Characteristics
| Attribute | Value |
|-----------|-------|
| Coverage | ~3 million products worldwide |
| Update Frequency | Real-time (community contributions) |
| Data Quality | Variable (user-submitted) |
| Rate Limiting | None (but be respectful) |
| Authentication | None required |

#### Limitations
- **Incomplete coverage**: Many products not in database, especially regional/local products
- **Variable quality**: User-submitted data may contain errors or be outdated
- **Ingredient parsing**: Raw text format varies by product and language
- **Missing products**: New products may not be added immediately
- **Regional availability**: US/EU have better coverage than other regions

---

### 2. IARC Monographs

**URL**: https://monographs.iarc.who.int

**Purpose**: Carcinogen classifications

**Type**: Authoritative scientific source (WHO)

#### What We Use
- Substance names and classifications
- Group assignments (1, 2A, 2B, 3)
- CAS numbers for chemical identification

#### Classification Groups
| Group | Meaning | # of Agents |
|-------|---------|-------------|
| Group 1 | Carcinogenic to humans | ~120 |
| Group 2A | Probably carcinogenic | ~90 |
| Group 2B | Possibly carcinogenic | ~320 |
| Group 3 | Not classifiable | ~500 |

#### Characteristics
| Attribute | Value |
|-----------|-------|
| Authority | WHO - highest scientific authority |
| Update Frequency | Ongoing (individual monographs) |
| Review Process | Expert panels, multi-year reviews |
| Coverage | Chemicals, occupational exposures, lifestyle factors |

#### Limitations
- **Focus on hazard, not risk**: IARC identifies *whether* something can cause cancer, not *how likely* it is at typical exposures
- **Binary outcomes**: No dose-response information in classifications
- **Slow updates**: Comprehensive reviews take years
- **Limited food coverage**: Many food additives not specifically evaluated
- **Context-free**: Doesn't account for typical dietary exposure levels

---

### 3. California Proposition 65

**URL**: https://oehha.ca.gov/proposition-65

**Purpose**: Additional carcinogen and reproductive toxicant list

**Type**: Regulatory (state law)

#### What We Use
- Listed chemicals and their classifications
- Cancer vs reproductive toxicity categorization

#### Characteristics
| Attribute | Value |
|-----------|-------|
| Authority | California OEHHA |
| Update Frequency | Annual updates |
| Coverage | ~900 chemicals |
| Threshold | "No significant risk level" defined |

#### Limitations
- **Precautionary approach**: Lower evidence threshold than IARC
- **California-specific**: Regulatory requirements may not reflect global scientific consensus
- **Over-broad warnings**: Many safe products carry Prop 65 warnings
- **No dose context**: Listing doesn't indicate dangerous exposure levels
- **Business influence**: Some listings are litigation-driven

---

## Data Integration

### How Sources Are Combined

```
┌─────────────────┐     ┌─────────────────┐
│ Open Food Facts │     │     Backend     │
│   (Products)    │────▶│  (Processing)   │
└─────────────────┘     └────────┬────────┘
                                 │
         ┌───────────────────────┼───────────────────────┐
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│    Ingredient   │     │   IARC Rules    │     │  Prop 65 Rules  │
│  Normalization  │────▶│  (in backend)   │────▶│  (in backend)   │
└─────────────────┘     └─────────────────┘     └─────────────────┘
                                 │
                                 ▼
                        ┌─────────────────┐
                        │  Risk Decision  │
                        └─────────────────┘
```

### Conflict Resolution Priority

When an ingredient appears in multiple sources:
1. **IARC Group 1** takes precedence (known carcinogen)
2. **IARC Group 2A** next (probable carcinogen)
3. **IARC Group 2B** (possible carcinogen)
4. **Prop 65** listings
5. **IARC Group 3** (not classifiable)

---

## Data Currency

### Last Updated
- **IARC data**: Based on monographs through 2024
- **Prop 65 data**: Based on list as of December 2024
- **Rules version**: 1.0.0

### Update Process
The backend rules file (`rules.py`) contains versioned classification data. Updates require:
1. Review of new IARC monographs or Prop 65 additions
2. Manual update to rules file
3. Version increment
4. Backend redeployment

---

## Known Gaps and Limitations

### Coverage Gaps
| Gap | Impact | Mitigation |
|-----|--------|------------|
| Many additives not classified | Unknown ingredients show as "safe" | Conservative default; document limitation |
| Regional products missing | No analysis possible | Encourage Open Food Facts contributions |
| Non-English ingredients | May not normalize correctly | Expand ingredient_map.json |
| New chemicals | Not immediately classified | Regular updates to rules |

### Scientific Limitations
1. **Dose matters**: A detected ingredient doesn't mean harmful exposure
2. **Individual variation**: Cancer risk depends on genetics, lifestyle, etc.
3. **Cumulative effects**: Multiple low-risk ingredients may interact
4. **Processing changes**: Cooking can create carcinogens not in raw ingredients
5. **Bioavailability**: Not all detected substances are absorbed

### Technical Limitations
1. **OCR errors**: Product data from images may be incorrect
2. **Translation issues**: Ingredient names vary by language
3. **Formatting variation**: Ingredient lists have no standard format
4. **Stale cache**: Cached results may not reflect updated products

---

## Data Accuracy Disclaimer

SafeEats provides information **"as-is"** with the following caveats:

1. **Open Food Facts data** is community-maintained and may contain errors
2. **Risk classifications** are simplified from complex scientific assessments
3. **Updates lag** behind new scientific publications
4. **Context is lost** in the simplification from detailed monographs
5. **Regional differences** in products, regulations, and ingredients exist

**This information is for educational purposes only and does not constitute medical or dietary advice.**

---

## Contributing

### Improving Data Quality

1. **Open Food Facts**: Contribute product data at https://world.openfoodfacts.org
2. **Ingredient mappings**: Submit PRs to expand `backend/data/ingredient_map.json`
3. **Risk rules**: Suggest additions with scientific citations

### Reporting Issues

If you find incorrect data:
1. Verify against original sources (IARC, Prop 65)
2. Open an issue with documentation
3. Suggest specific corrections

---

## References

### Primary Sources
- IARC Monographs: https://monographs.iarc.who.int/list-of-classifications
- Prop 65 List: https://oehha.ca.gov/proposition-65/chemicals
- Open Food Facts: https://world.openfoodfacts.org/data

### Scientific Background
- WHO IARC Preamble: https://monographs.iarc.who.int/iarc-monographs-preamble-preamble-to-the-iarc-monographs/
- Prop 65 Science: https://oehha.ca.gov/proposition-65/science

### Food Safety
- FDA Food Additives: https://www.fda.gov/food/food-additives-petitions/food-additive-status-list
- EFSA (EU): https://www.efsa.europa.eu/en/topics/topic/food-additives