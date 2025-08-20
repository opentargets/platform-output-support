from pydantic import BaseModel


class GCPLabels(BaseModel):
    """GCP labels.

    Args:
        team (str): Team
        subteam (str): Subteam
        product (str): Product
        tool (str): Tool
        release (str): Release name, defaults to empty string
    """

    team: str = 'open-targets'
    subteam: str = 'backend'
    product: str = 'platform'
    tool: str = 'pos'
    release: str = ''
