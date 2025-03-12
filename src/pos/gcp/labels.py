from pydantic import BaseModel


class GCPLabels(BaseModel):
    """GCP labels.

    Arguments:
        team -- Team
        subteam -- Subteam
        product -- Product
        tool -- Tool
    """

    team: str = 'open-targets'
    subteam: str = 'backend'
    product: str = 'platform'
    tool: str = 'pos'
