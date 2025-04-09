
## CrewAI 

This sample uses [CrewAI](https://www.crewai.com/open-source) to build a simple image generation agent and host it as an A2A server. 

## Prerequisites

- Python 3.12 or higher
- UV
- Access to an LLM and API Key

## Running the Sample

1. Navigate to the samples directory:
    ```bash
    cd samples/agents/crewai
    ```
2. Create a file named .env under agents/crewai. 
    ```bash
    touch .env
    ```
3. Add GOOGLE_API_KEY to .env (sample uses Google Gemini by default)

4. Run the agent:
    ```bash
    uv python pin 3.12
    uv venv
    source .venv/bin/activate
    uv run .
    ```
5. Run the client
    ```
    uv run hosts/cli
    ```