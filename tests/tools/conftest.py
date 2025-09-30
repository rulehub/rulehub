"""Pytest configuration for tools tests.

Ensures the repository root is on sys.path so that 'import tools' works
when running tests directly via pytest.
"""

from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
root_str = str(ROOT)
if root_str not in sys.path:
    sys.path.insert(0, root_str)
