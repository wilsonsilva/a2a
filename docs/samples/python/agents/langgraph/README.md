
## LangGraph 

This sample uses [LangGraph](https://langchain-ai.github.io/langgraph/) to build a simple Currency Converter agent and host it as an A2A server.

The agent supports multi-turn for completing the currency conversion tasks. For example, the agent sets the task to `input-required` if additional user input is required to complete the task and accepts additional user input.

## Prerequisites

- Python 3.13 or higher
- UV
- Access to an LLM and API Key

## Running the Sample

1. Navigate to the samples directory:
    ```bash
    cd samples/python
    ```
2. Create a file named .env under agents/crewai. 
    ```bash
    touch agents/langgraph/.env
    ```
3. Add `GOOGLE_API_KEY` to .env  (sample uses Google Gemini by default)

4. Run an agent:
    ```bash
    uv run langgraph/agent
    ```
5. Run one of the [client apps](/samples/python/hosts/README.md)

## Examples

**Synchronous request**

Request:
```
POST http://localhost:10000
Content-Type: application/json

{
  "jsonrpc": "2.0",
  "id": 11,
  "method": "tasks/send",
  "params": {
    "id": "129",
    "sessionId": "8f01f3d172cd4396a0e535ae8aec6687",
    "acceptedOutputModes": [
      "text"
    ],
    "message": {
      "role": "user",
      "parts": [
        {
          "type": "text",
          "text": "How much is the exchange rate for 1 USD to INR?"
        }
      ]
    }
  }
}
```

Response:

```
{
  "jsonrpc": "2.0",
  "id": 11,
  "result": {
    "id": "129",
    "status": {
      "state": "completed",
      "timestamp": "2025-04-02T16:53:29.301828"
    },
    "artifacts": [
      {
        "parts": [
          {
            "type": "text",
            "text": "The exchange rate for 1 USD to INR is 85.49."
          }
        ],
        "index": 0
      }
    ],
    "history": []
  }
}
```

**Multi-turn example**

Request - Seq 1:

```
POST http://localhost:10000
Content-Type: application/json

{
  "jsonrpc": "2.0",
  "id": 10,
  "method": "tasks/send",
  "params": {
    "id": "130",
    "sessionId": "a9bb617f2cd94bd585da0f88ce2ddba2",
    "acceptedOutputModes": [
      "text"
    ],
    "message": {
      "role": "user",
      "parts": [
        {
          "type": "text",
          "text": "How much is the exchange rate for 1 USD?"
        }
      ]
    }
  }
}
```

Response - Seq 2:

```
{
  "jsonrpc": "2.0",
  "id": 10,
  "result": {
    "id": "130",
    "status": {
      "state": "input-required",
      "message": {
        "role": "agent",
        "parts": [
          {
            "type": "text",
            "text": "Which currency do you want to convert to? Also, do you want the latest exchange rate or a specific date?"
          }
        ]
      },
      "timestamp": "2025-04-02T16:57:02.336787"
    },
    "history": []
  }
}
```

Request - Seq 3:

```
POST http://localhost:10000
Content-Type: application/json

{
  "jsonrpc": "2.0",
  "id": 10,
  "method": "tasks/send",
  "params": {
    "id": "130",
    "sessionId": "a9bb617f2cd94bd585da0f88ce2ddba2",
    "acceptedOutputModes": [
      "text"
    ],
    "message": {
      "role": "user",
      "parts": [
        {
          "type": "text",
          "text": "CAD"
        }
      ]
    }
  }
}
```

Response - Seq 4:

```
{
  "jsonrpc": "2.0",
  "id": 10,
  "result": {
    "id": "130",
    "status": {
      "state": "completed",
      "timestamp": "2025-04-02T16:57:40.033328"
    },
    "artifacts": [
      {
        "parts": [
          {
            "type": "text",
            "text": "The current exchange rate is 1 USD = 1.4328 CAD."
          }
        ],
        "index": 0
      }
    ],
    "history": []
  }
}
```

**Streaming example**

Request:

```
{
  "jsonrpc": "2.0",
  "id": 12,
  "method": "tasks/sendSubscribe",
  "params": {
    "id": "131",
    "sessionId": "cebd704d0ddd4e8aa646aeb123d60614",
    "acceptedOutputModes": [
      "text"
    ],
    "message": {
      "role": "user",
      "parts": [
        {
          "type": "text",
          "text": "How much is 100 USD in GBP?"
        }
      ]
    }
  }
}
```

Response:

```
data: {"jsonrpc":"2.0","id":12,"result":{"id":"131","status":{"state":"working","message":{"role":"agent","parts":[{"type":"text","text":"Looking up the exchange rates..."}]},"timestamp":"2025-04-02T16:59:34.578939"},"final":false}}

data: {"jsonrpc":"2.0","id":12,"result":{"id":"131","status":{"state":"working","message":{"role":"agent","parts":[{"type":"text","text":"Processing the exchange rates.."}]},"timestamp":"2025-04-02T16:59:34.737052"},"final":false}}

data: {"jsonrpc":"2.0","id":12,"result":{"id":"131","artifact":{"parts":[{"type":"text","text":"Based on the current exchange rate, 1 USD is equivalent to 0.77252 GBP. Therefore, 100 USD would be approximately 77.252 GBP."}],"index":0,"append":false}}}

data: {"jsonrpc":"2.0","id":12,"result":{"id":"131","status":{"state":"completed","timestamp":"2025-04-02T16:59:35.331844"},"final":true}}
```