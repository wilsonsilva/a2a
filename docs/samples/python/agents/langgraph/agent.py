from langchain_google_genai import ChatGoogleGenerativeAI
from langchain_core.tools import tool
from langgraph.prebuilt import create_react_agent
from langgraph.checkpoint.memory import MemorySaver
from langchain_core.messages import AIMessage, ToolMessage, HumanMessage
import httpx
from typing import Any, Dict, AsyncIterable

memory = MemorySaver()


@tool
def get_exchange_rate(
    currency_from: str = "USD",
    currency_to: str = "EUR",
    currency_date: str = "latest",
):
    """Use this to get current exchange rate.

    Args:
        currency_from: The currency to convert from (e.g., "USD").
        currency_to: The currency to convert to (e.g., "EUR").
        currency_date: The date for the exchange rate or "latest". Defaults to "latest".

    Returns:
        A dictionary containing the exchange rate data, or an error message if the request fails.
    """
    try:
        response = httpx.get(
            f"https://api.frankfurter.app/{currency_date}",
            params={"from": currency_from, "to": currency_to},
        )
        response.raise_for_status()

        data = response.json()
        if "rates" not in data:
            return {"error": "Invalid API response format."}
        return data
    except httpx.HTTPError as e:
        return {"error": f"API request failed: {e}"}
    except ValueError:
        return {"error": "Invalid JSON response from API."}


class CurrencyAgent:
    def __init__(self):
        self.model = ChatGoogleGenerativeAI(model="gemini-2.0-flash")
        self.tools = [get_exchange_rate]
        self.graph = create_react_agent(
            self.model, tools=self.tools, checkpointer=memory
        )

    def invoke(self, query, sessionId) -> str:
        config = {"configurable": {"thread_id": sessionId}}
        self.graph.invoke({"messages": [("user", query)]}, config)
        return self.get_agent_response(config)

    async def stream(self, query, sessionId) -> AsyncIterable[Dict[str, Any]]:
        inputs = {"messages": [("user", query)]}
        config = {"configurable": {"thread_id": sessionId}}

        for item in self.graph.stream(inputs, config, stream_mode="values"):
            message = item["messages"][-1]
            if (
                isinstance(message, AIMessage)
                and message.tool_calls
                and len(message.tool_calls) > 0
            ):
                yield {
                    "is_task_complete": False,
                    "require_user_input": False,
                    "content": "Looking up the exchange rates...",
                }
            elif isinstance(message, ToolMessage):
                yield {
                    "is_task_complete": False,
                    "require_user_input": False,
                    "content": "Processing the exchange rates..",
                }
        yield self.get_agent_response(config)

    def get_agent_response(self, config):
        current_state = self.graph.get_state(config)
        messages = current_state.values["messages"]

        last_message = messages[-1]

        # from the last message check if there is a ToolMessage before we hit a HumanMessage
        # if there is ToolMessage, we assume the tool is invoked and we have final response
        # if not we assume the tool needs additional inputs from user
        for i in range(len(messages) - 2, 0, -1):
            current = messages[i]
            if isinstance(current, ToolMessage):
                return {
                    "is_task_complete": True,
                    "require_user_input": False,
                    "content": last_message.content,
                }
            elif isinstance(current, HumanMessage):
                break

        return {
            "is_task_complete": False,
            "require_user_input": True,
            "content": last_message.content,
        }

    SUPPORTED_CONTENT_TYPES = ["text", "text/plain"]
