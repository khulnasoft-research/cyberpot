"""Unit tests for the forensics collector module."""
import pytest
from unittest.mock import patch, MagicMock, mock_open
from pathlib import Path

# Import the module we want to test
from enterprise.security_tools.forensics.forensics_collector import (
    DigitalForensicsCollector,
    EvidenceItem,
    TimelineEntry
)

class TestEvidenceItem:
    """Test the EvidenceItem class."""
    
    def test_evidence_item_creation(self):
        """Test creating an evidence item."""
        evidence = EvidenceItem(
            id="test-123",
            name="test_evidence",
            description="Test evidence item",
            evidence_type="file",
            source="/path/to/file",
            collected_at="2023-01-01T00:00:00",
            collection_method="manual"
        )
        
        assert evidence.id == "test-123"
        assert evidence.name == "test_evidence"
        assert evidence.evidence_type == "file"


class TestDigitalForensicsCollector:
    """Test the DigitalForensicsCollector class."""
    
    @pytest.fixture
    def collector(self, tmp_path):
        """Create a test collector with a temporary directory."""
        return DigitalForensicsCollector("test_case", tmp_path)
    
    def test_initialization(self, collector, tmp_path):
        """Test that the collector initializes correctly."""
        assert collector.case_id == "test_case"
        assert collector.evidence_path == tmp_path
        assert collector.case_path == tmp_path / "test_case"
        
        # Check that the directory structure was created
        assert (tmp_path / "test_case").exists()
        assert (tmp_path / "test_case" / "evidence").exists()
        assert (tmp_path / "test_case" / "reports").exists()
    
    @patch('subprocess.run')
    def test_collect_system_evidence(self, mock_run, collector):
        """Test collecting system evidence."""
        # Mock the subprocess.run calls
        mock_run.return_value = MagicMock(returncode=0, stdout=b"test output")
        
        collector.collect_system_evidence()
        
        # Verify that the expected commands were run
        assert mock_run.call_count > 0
        
    def test_analyze_incident_patterns(self, collector):
        """Test analyzing incident patterns."""
        # Add some test evidence
        collector.evidence_items = [
            EvidenceItem(
                id="1",
                name="suspicious_process",
                evidence_type="process",
                source="test",
                collected_at="now",
                collection_method="test"
            )
        ]
        
        analysis = collector.analyze_incident_patterns()
        
        assert isinstance(analysis, dict)
        assert "suspicious_processes" in analysis
        assert "network_anomalies" in analysis
        assert "file_anomalies" in analysis
