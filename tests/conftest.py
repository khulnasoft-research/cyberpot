"""Pytest configuration and fixtures."""
import sys
from pathlib import Path

# Add the project root to the Python path
project_root = Path(__file__).parent.resolve()
sys.path.insert(0, str(project_root))

# Common fixtures can be defined here
import pytest
from unittest.mock import MagicMock

@pytest.fixture
def mock_config():
    """Mock configuration for testing."""
    return {
        'base_path': '/tmp/cyberpot_test',
        'environment': 'test',
        'provider': 'local',
        'region': 'test-region'
    }

@pytest.fixture
def mock_logger():
    """Mock logger for testing."""
    logger = MagicMock()
    logger.info = MagicMock()
    logger.error = MagicMock()
    logger.warning = MagicMock()
    logger.debug = MagicMock()
    return logger
