from pydantic import BaseModel


class GCPLabels(BaseModel):
    """GCP labels.

    Args:
        team: Team
        subteam: Subteam
        product: Product
        tool: Tool
    """

    team: str = 'open-targets'
    subteam: str = 'backend'
    product: str = 'platform'
    tool: str = 'pos'
