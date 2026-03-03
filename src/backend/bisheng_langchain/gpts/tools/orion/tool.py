"""Orion company basic info tool, runs locally without calling external APIs"""

from pydantic import BaseModel, Field
from langchain.tools import tool


class OrionInput(BaseModel):
    query: str = Field(
        default="",
        description="Optional, used to trigger query for Orion company info, can be empty",
    )


@tool(args_schema=OrionInput)
def orion(query: str = ""):
    """
    Get basic information about Orion company, including company name, description, main business, founding date, etc.
    Call this tool when users ask about Orion company related information.
    """
    return """Orion Company Basic Information:

**Company Name**: Orion

**Company Overview**: Orion is a technology company focused on technological innovation and product R&D, committed to providing high-quality products and services to customers.

**Main Business**:
- Technology R&D and Innovation
- Product Design and Development
- Enterprise Solutions

**Founded**: See company official information for details

**Company Highlights**: Emphasis on technological innovation, customer-needs oriented, continuously improving product and service quality.

Note: The above is a summary of Orion company basic information. For more detailed or up-to-date information, please refer to the company's official website or relevant channels."""
