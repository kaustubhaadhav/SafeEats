"""
Risk classification rules for ingredients.

SafeEats uses a deterministic rule-based system to classify ingredient risks.
This module centralizes all risk classification logic.

Risk levels (aligned with Flutter RiskLevel enum):
- "safe"     : No known concerns
- "low"      : Minor concerns, limited evidence
- "moderate" : Possible carcinogen (IARC Group 2B or similar)
- "high"     : Probable carcinogen (IARC Group 2A or similar)
- "critical" : Known carcinogen (IARC Group 1)

Source Priority (for conflict resolution):
When multiple sources classify the same ingredient differently,
we use the following priority order (higher = more authoritative):
1. IARC Group 1 (known carcinogen)
2. IARC Group 2A (probable carcinogen)
3. IARC Group 2B (possible carcinogen)
4. Prop 65 (California toxicant list)
5. IARC Group 3 (not classifiable)
"""


from typing import TypedDict, Optional


# =============================================================================
# VERSION INFORMATION
# =============================================================================

RULES_VERSION = "1.0.0"
RULES_LAST_UPDATED = "2024-12-24"

RULES_METADATA = {
    "version": RULES_VERSION,
    "last_updated": RULES_LAST_UPDATED,
    "sources": [
        "IARC Monographs on the Identification of Carcinogenic Hazards to Humans",
        "California Proposition 65 (Safe Drinking Water and Toxic Enforcement Act)"
    ],
    "conflict_resolution": "IARC classifications take precedence over Prop 65 when both sources classify an ingredient. Within IARC, Group 1 > 2A > 2B > 3.",
    "disclaimer": "This classification system is for informational purposes only. Risk assessments are based on published scientific data but do not constitute medical advice."
}


# =============================================================================
# SOURCE PRIORITY FOR CONFLICT RESOLUTION
# =============================================================================

SOURCE_PRIORITY = {
    "IARC_GROUP_1": 100,   # Known carcinogen - highest authority
    "IARC_GROUP_2A": 90,   # Probable carcinogen
    "IARC_GROUP_2B": 80,   # Possible carcinogen
    "PROP65_CARCINOGEN": 70,  # California carcinogen list
    "PROP65_REPRODUCTIVE": 65,  # California reproductive toxicant
    "IARC_GROUP_3": 60,    # Not classifiable
    "NONE": 0,             # No classification
}


# =============================================================================
# RISK LEVEL MAPPING
# =============================================================================

# Maps source classifications to risk levels
SOURCE_TO_RISK = {
    "IARC_GROUP_1": "critical",
    "IARC_GROUP_2A": "high",
    "IARC_GROUP_2B": "moderate",
    "PROP65_CARCINOGEN": "high",
    "PROP65_REPRODUCTIVE": "moderate",
    "IARC_GROUP_3": "low",
    "NONE": "safe",
}


# =============================================================================
# INGREDIENT RISK RULES
# =============================================================================

class RiskRule(TypedDict):
    """Type definition for risk rules."""
    risk: str
    source: str
    iarc_group: Optional[str]
    notes: str


# Deterministic risk rules for canonical ingredient names
# Each rule includes the source for transparency and conflict resolution
RISK_RULES: dict[str, RiskRule] = {
    # =========================================================================
    # CRITICAL RISK - IARC Group 1 (Known carcinogens)
    # =========================================================================
    "processed meat": {
        "risk": "critical",
        "source": "IARC_GROUP_1",
        "iarc_group": "Group 1",
        "notes": "Classified as carcinogenic to humans in 2015. Includes hot dogs, ham, sausages, corned beef, beef jerky."
    },
    "alcohol": {
        "risk": "critical",
        "source": "IARC_GROUP_1",
        "iarc_group": "Group 1",
        "notes": "Ethanol in alcoholic beverages is carcinogenic. Associated with cancers of mouth, throat, liver, breast."
    },
    "ethanol": {
        "risk": "critical",
        "source": "IARC_GROUP_1",
        "iarc_group": "Group 1",
        "notes": "Same as alcohol - ethanol in alcoholic beverages."
    },
    
    # =========================================================================
    # HIGH RISK - IARC Group 2A (Probable carcinogens)
    # =========================================================================
    "acrylamide": {
        "risk": "high",
        "source": "IARC_GROUP_2A",
        "iarc_group": "Group 2A",
        "notes": "Forms in starchy foods during high-temperature cooking (frying, baking, roasting)."
    },
    "red meat": {
        "risk": "high",
        "source": "IARC_GROUP_2A",
        "iarc_group": "Group 2A",
        "notes": "Unprocessed mammalian muscle meat. Classified as probably carcinogenic in 2015."
    },
    "sodium nitrite": {
        "risk": "high",
        "source": "IARC_GROUP_2A",
        "iarc_group": "Group 2A",
        "notes": "Preservative in cured meats. Can form carcinogenic nitrosamines."
    },
    "sodium nitrate": {
        "risk": "high",
        "source": "IARC_GROUP_2A",
        "iarc_group": "Group 2A",
        "notes": "Converts to nitrite in the body. Used in cured meats."
    },
    "erythrosine": {
        "risk": "high",
        "source": "PROP65_CARCINOGEN",
        "iarc_group": None,
        "notes": "Red Dye No. 3 (E127). Linked to thyroid tumors in animal studies. FDA banned in cosmetics."
    },
    "titanium dioxide": {
        "risk": "high",
        "source": "IARC_GROUP_2B",
        "iarc_group": "Group 2B",
        "notes": "Food whitening agent (E171). Banned as food additive in EU since 2022. Elevated to high due to regulatory action."
    },
    "partially hydrogenated oil": {
        "risk": "high",
        "source": "PROP65_CARCINOGEN",
        "iarc_group": None,
        "notes": "Contains trans fats. FDA determined not GRAS (Generally Recognized as Safe) in 2015."
    },
    "glyphosate": {
        "risk": "high",
        "source": "IARC_GROUP_2A",
        "iarc_group": "Group 2A",
        "notes": "Herbicide residue. Classified as probably carcinogenic in 2015."
    },
    
    # =========================================================================
    # MODERATE RISK - IARC Group 2B (Possible carcinogens) or health concerns
    # =========================================================================
    "aspartame": {
        "risk": "moderate",
        "source": "IARC_GROUP_2B",
        "iarc_group": "Group 2B",
        "notes": "Artificial sweetener (E951). Classified as possibly carcinogenic in July 2023."
    },
    "monosodium glutamate": {
        "risk": "moderate",
        "source": "PROP65_REPRODUCTIVE",
        "iarc_group": None,
        "notes": "MSG (E621). Some individuals report sensitivity. Generally recognized as safe by FDA."
    },
    "sodium benzoate": {
        "risk": "moderate",
        "source": "PROP65_CARCINOGEN",
        "iarc_group": None,
        "notes": "Preservative (E211). Can form benzene when combined with vitamin C (ascorbic acid)."
    },
    "caramel color": {
        "risk": "moderate",
        "source": "PROP65_CARCINOGEN",
        "iarc_group": None,
        "notes": "Specifically 4-MEI in Class III and IV caramel colors (E150c, E150d). Listed under Prop 65."
    },
    "butylated hydroxyanisole": {
        "risk": "moderate",
        "source": "IARC_GROUP_2B",
        "iarc_group": "Group 2B",
        "notes": "BHA (E320). Antioxidant preservative. Possibly carcinogenic to humans."
    },
    "butylated hydroxytoluene": {
        "risk": "moderate",
        "source": "IARC_GROUP_3",
        "iarc_group": "Group 3",
        "notes": "BHT (E321). Not classifiable by IARC but has some health concerns."
    },
    "tertiary butylhydroquinone": {
        "risk": "moderate",
        "source": "PROP65_CARCINOGEN",
        "iarc_group": None,
        "notes": "TBHQ (E319). Antioxidant in processed foods. Limited evidence of carcinogenicity."
    },
    "acesulfame potassium": {
        "risk": "moderate",
        "source": "PROP65_REPRODUCTIVE",
        "iarc_group": None,
        "notes": "Ace-K (E950). Artificial sweetener. Some studies suggest potential health effects."
    },
    "saccharin": {
        "risk": "moderate",
        "source": "IARC_GROUP_3",
        "iarc_group": "Group 3",
        "notes": "Artificial sweetener (E954). Delisted from carcinogen lists but some concerns remain."
    },
    "cyclamate": {
        "risk": "moderate",
        "source": "PROP65_CARCINOGEN",
        "iarc_group": None,
        "notes": "Artificial sweetener (E952). Banned in US but permitted in EU."
    },
    "carrageenan": {
        "risk": "moderate",
        "source": "PROP65_CARCINOGEN",
        "iarc_group": None,
        "notes": "Thickener (E407). Degraded form (poligeenan) has concerns. Food-grade generally considered safe."
    },
    "high fructose corn syrup": {
        "risk": "moderate",
        "source": "PROP65_REPRODUCTIVE",
        "iarc_group": None,
        "notes": "HFCS. Associated with metabolic health concerns, not directly carcinogenic."
    },
    "potassium bromate": {
        "risk": "moderate",
        "source": "IARC_GROUP_2B",
        "iarc_group": "Group 2B",
        "notes": "Flour improver. Banned in EU, Canada, Brazil. Still permitted in US."
    },
    "propyl paraben": {
        "risk": "moderate",
        "source": "PROP65_REPRODUCTIVE",
        "iarc_group": None,
        "notes": "Preservative (E216). Endocrine disrupting properties."
    },
    
    # =========================================================================
    # LOW RISK - Minor concerns or limited evidence
    # =========================================================================
    "allura red": {
        "risk": "low",
        "source": "IARC_GROUP_3",
        "iarc_group": "Group 3",
        "notes": "Red 40 (E129). Most common red food dye. Not classifiable as carcinogenic."
    },
    "tartrazine": {
        "risk": "low",
        "source": "IARC_GROUP_3",
        "iarc_group": "Group 3",
        "notes": "Yellow 5 (E102). May cause allergic reactions in sensitive individuals."
    },
    "sunset yellow": {
        "risk": "low",
        "source": "IARC_GROUP_3",
        "iarc_group": "Group 3",
        "notes": "Yellow 6 (E110). Not classifiable as carcinogenic."
    },
    "brilliant blue": {
        "risk": "low",
        "source": "IARC_GROUP_3",
        "iarc_group": "Group 3",
        "notes": "Blue 1 (E133). Poorly absorbed. Not classifiable as carcinogenic."
    },
    "indigo carmine": {
        "risk": "low",
        "source": "IARC_GROUP_3",
        "iarc_group": "Group 3",
        "notes": "Blue 2 (E132). Not classifiable as carcinogenic."
    },
    "sucralose": {
        "risk": "low",
        "source": "NONE",
        "iarc_group": None,
        "notes": "Artificial sweetener (E955). Generally considered safe. Some emerging concerns."
    },
    "potassium sorbate": {
        "risk": "low",
        "source": "NONE",
        "iarc_group": None,
        "notes": "Preservative (E202). Generally recognized as safe."
    },
    "sorbic acid": {
        "risk": "low",
        "source": "NONE",
        "iarc_group": None,
        "notes": "Preservative (E200). Generally recognized as safe."
    },
    "citric acid": {
        "risk": "low",
        "source": "NONE",
        "iarc_group": None,
        "notes": "Acidulant (E330). Natural compound, generally safe."
    },
    "ascorbic acid": {
        "risk": "low",
        "source": "NONE",
        "iarc_group": None,
        "notes": "Vitamin C (E300). Essential nutrient. Can react with benzoates to form benzene."
    },
    "lecithin": {
        "risk": "low",
        "source": "NONE",
        "iarc_group": None,
        "notes": "Emulsifier (E322). Natural compound from soy, sunflower, or eggs."
    },
    "xanthan gum": {
        "risk": "low",
        "source": "NONE",
        "iarc_group": None,
        "notes": "Thickener (E415). Fermentation product. Generally safe."
    },
    "guar gum": {
        "risk": "low",
        "source": "NONE",
        "iarc_group": None,
        "notes": "Thickener (E412). Plant-derived. Generally safe."
    },
}

DEFAULT_RISK = "safe"
DEFAULT_SOURCE = "NONE"


# =============================================================================
# FUNCTIONS
# =============================================================================

def get_risk(canonical_name: str) -> str:
    """
    Returns the risk level for a canonical ingredient name.
    
    Args:
        canonical_name: Normalized ingredient name (lowercase, trimmed)
        
    Returns:
        Risk level string: "safe", "low", "moderate", "high", or "critical"
    """
    rule = RISK_RULES.get(canonical_name.lower())
    if rule:
        return rule["risk"]
    return DEFAULT_RISK


def get_risk_with_source(canonical_name: str) -> tuple[str, str, Optional[str]]:
    """
    Returns the risk level, source, and notes for a canonical ingredient name.
    
    This function provides full transparency about why an ingredient
    received its risk classification.
    
    Args:
        canonical_name: Normalized ingredient name (lowercase, trimmed)
        
    Returns:
        Tuple of (risk_level, source, notes)
    """
    rule = RISK_RULES.get(canonical_name.lower())
    if rule:
        return rule["risk"], rule["source"], rule.get("notes")
    return DEFAULT_RISK, DEFAULT_SOURCE, None


def get_overall_risk(risks: list[str]) -> str:
    """
    Returns the highest risk level from a list of risks.
    
    The risk hierarchy from highest to lowest:
    critical > high > moderate > low > safe
    
    Args:
        risks: List of risk level strings
        
    Returns:
        The highest risk level found, or "safe" if list is empty
    """
    if not risks:
        return DEFAULT_RISK
    
    risk_order = {"safe": 0, "low": 1, "moderate": 2, "high": 3, "critical": 4}
    max_risk = max(risks, key=lambda r: risk_order.get(r, 0))
    return max_risk


def get_rules_version() -> str:
    """Returns the current rules version string."""
    return RULES_VERSION


def get_rules_metadata() -> dict:
    """Returns the complete rules metadata dictionary."""
    return RULES_METADATA.copy()