"""
Tests for the risk classification rules module.

Tests cover:
1. Risk classification for known ingredients
2. Overall risk calculation
3. Source tracking and conflict resolution
4. Version information
"""


import sys
from pathlib import Path

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent))

from rules import (
    get_risk,
    get_risk_with_source,
    get_overall_risk,
    get_rules_version,
    get_rules_metadata,
    RULES_VERSION,
    RISK_RULES,
)


class TestRiskClassification:
    """Tests for the get_risk() function."""
    
    def test_known_carcinogen_returns_critical(self):
        """IARC Group 1 ingredients should return critical risk."""
        assert get_risk("processed meat") == "critical"
        assert get_risk("alcohol") == "critical"
        assert get_risk("ethanol") == "critical"
    
    def test_probable_carcinogen_returns_high(self):
        """IARC Group 2A ingredients should return high risk."""
        assert get_risk("acrylamide") == "high"
        assert get_risk("sodium nitrite") == "high"
        assert get_risk("glyphosate") == "high"
    
    def test_possible_carcinogen_returns_moderate(self):
        """IARC Group 2B or Prop 65 ingredients should return moderate risk."""
        assert get_risk("aspartame") == "moderate"
        assert get_risk("monosodium glutamate") == "moderate"
        assert get_risk("sodium benzoate") == "moderate"
    
    def test_minor_concern_returns_low(self):
        """Ingredients with limited evidence should return low risk."""
        assert get_risk("allura red") == "low"
        assert get_risk("tartrazine") == "low"
        assert get_risk("sucralose") == "low"
    
    def test_unknown_ingredient_returns_safe(self):
        """Unknown ingredients should return safe (default)."""
        assert get_risk("water") == "safe"
        assert get_risk("salt") == "safe"
        assert get_risk("sugar") == "safe"
        assert get_risk("totally_made_up_ingredient") == "safe"
    
    def test_case_insensitive(self):
        """Risk lookup should be case-insensitive."""
        assert get_risk("Aspartame") == "moderate"
        assert get_risk("ASPARTAME") == "moderate"
        assert get_risk("AsParTaMe") == "moderate"


class TestRiskWithSource:
    """Tests for the get_risk_with_source() function."""
    
    def test_returns_source_for_known_ingredient(self):
        """Should return risk, source, and notes for known ingredients."""
        risk, source, notes = get_risk_with_source("processed meat")
        assert risk == "critical"
        assert source == "IARC_GROUP_1"
        assert notes is not None
        assert "carcinogenic" in notes.lower()
    
    def test_returns_iarc_group_info(self):
        """Should include IARC group in source when applicable."""
        risk, source, notes = get_risk_with_source("aspartame")
        assert risk == "moderate"
        assert source == "IARC_GROUP_2B"
        assert "2023" in notes  # Year of classification
    
    def test_returns_prop65_source(self):
        """Should identify Prop 65 as source when applicable."""
        risk, source, notes = get_risk_with_source("erythrosine")
        assert risk == "high"
        assert "PROP65" in source
    
    def test_returns_none_source_for_unknown(self):
        """Unknown ingredients should return NONE source."""
        risk, source, notes = get_risk_with_source("water")
        assert risk == "safe"
        assert source == "NONE"
        assert notes is None


class TestOverallRisk:
    """Tests for the get_overall_risk() function."""
    
    def test_returns_highest_risk(self):
        """Should return the highest risk level from the list."""
        risks = ["low", "moderate", "high", "low"]
        assert get_overall_risk(risks) == "high"
    
    def test_critical_takes_precedence(self):
        """Critical should always win."""
        risks = ["safe", "low", "moderate", "high", "critical"]
        assert get_overall_risk(risks) == "critical"
    
    def test_empty_list_returns_safe(self):
        """Empty list should return safe."""
        assert get_overall_risk([]) == "safe"
    
    def test_single_item_returns_that_item(self):
        """Single item list should return that item."""
        assert get_overall_risk(["moderate"]) == "moderate"
    
    def test_all_safe_returns_safe(self):
        """List of all safe should return safe."""
        risks = ["safe", "safe", "safe"]
        assert get_overall_risk(risks) == "safe"


class TestVersioning:
    """Tests for version information."""
    
    def test_version_is_string(self):
        """Version should be a string."""
        assert isinstance(RULES_VERSION, str)
        assert isinstance(get_rules_version(), str)
    
    def test_version_follows_semver(self):
        """Version should follow semantic versioning format."""
        import re
        semver_pattern = r'^\d+\.\d+\.\d+$'
        assert re.match(semver_pattern, RULES_VERSION)
    
    def test_metadata_contains_required_fields(self):
        """Metadata should contain all required fields."""
        metadata = get_rules_metadata()
        assert "version" in metadata
        assert "last_updated" in metadata
        assert "sources" in metadata
        assert "conflict_resolution" in metadata
        assert "disclaimer" in metadata
    
    def test_metadata_is_copy(self):
        """get_rules_metadata should return a copy to prevent mutation."""
        metadata1 = get_rules_metadata()
        metadata1["version"] = "hacked"
        metadata2 = get_rules_metadata()
        assert metadata2["version"] == RULES_VERSION


class TestRulesIntegrity:
    """Tests for rules data integrity."""
    
    def test_all_rules_have_required_fields(self):
        """Each rule should have risk, source, and notes fields."""
        for ingredient, rule in RISK_RULES.items():
            assert "risk" in rule, f"Missing 'risk' for {ingredient}"
            assert "source" in rule, f"Missing 'source' for {ingredient}"
            assert "notes" in rule, f"Missing 'notes' for {ingredient}"
    
    def test_all_risk_levels_are_valid(self):
        """All risk levels should be one of the valid values."""
        valid_risks = {"safe", "low", "moderate", "high", "critical"}
        for ingredient, rule in RISK_RULES.items():
            assert rule["risk"] in valid_risks, f"Invalid risk level for {ingredient}: {rule['risk']}"
    
    def test_all_sources_are_valid(self):
        """All sources should be valid classification sources."""
        valid_sources = {
            "IARC_GROUP_1", "IARC_GROUP_2A", "IARC_GROUP_2B", "IARC_GROUP_3",
            "PROP65_CARCINOGEN", "PROP65_REPRODUCTIVE", "NONE"
        }
        for ingredient, rule in RISK_RULES.items():
            assert rule["source"] in valid_sources, f"Invalid source for {ingredient}: {rule['source']}"


class TestConflictResolution:
    """Tests for IARC vs Prop 65 conflict resolution."""
    
    def test_iarc_group1_highest_priority(self):
        """IARC Group 1 should have highest priority."""
        # If an ingredient is Group 1, it should be critical regardless of other sources
        risk, source, _ = get_risk_with_source("processed meat")
        assert risk == "critical"
        assert source == "IARC_GROUP_1"
    
    def test_iarc_takes_precedence_over_prop65(self):
        """
        For ingredients classified by both IARC and Prop 65,
        the IARC classification should be used.
        
        Note: This tests the rule design principle, not runtime conflict resolution,
        since each ingredient has a single authoritative entry.
        """
        # Aspartame is classified by both IARC (2B) and Prop 65
        # Our rules use IARC classification
        risk, source, _ = get_risk_with_source("aspartame")
        assert "IARC" in source, "IARC should be the source for aspartame"