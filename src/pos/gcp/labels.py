from pydantic import BaseModel


class GCPLabels(BaseModel):
    """GCP labels.

    Args:
        team (str): Team
        subteam (str): Subteam
        product (str): Product
        tool (str): Tool
        release (str|None): Release name, defaults to None
    """

    team: str = 'open-targets'
    subteam: str = 'backend'
    product: str = 'platform'
    tool: str = 'pos'
    release: str | None = None
