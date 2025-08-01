"""Initial empty revision

Revision ID: 30abf90312e1
Revises: 
Create Date: 2025-08-01 18:09:54.119565

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '30abf90312e1'
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Initial T1 scaffolding - no tables yet."""
    # No database schema changes in T1 phase
    # Tables will be added in future versions (T2+)
    pass


def downgrade() -> None:
    """Downgrade initial revision."""
    # No changes to downgrade
    pass
