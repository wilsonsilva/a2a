from common.server import A2AServer
from common.types import AgentCard, AgentCapabilities, AgentSkill
from task_manager import AgentTaskManager
from agent import ReimbursementAgent
import click

@click.command()
@click.option("--host", default="localhost")
@click.option("--port", default=10002)
def main(host, port):
    capabilities = AgentCapabilities(streaming=True)
    skill = AgentSkill(
        id="process_reimbursement",
        name="Process Reimbursement Tool",
        description="Helps with the reimbursement process for users given the amount and purpose of the reimbursement.",
        tags=["reimbursement"],
        examples=["Can you reimburse me $20 for my lunch with the clients?"],
    )
    agent_card = AgentCard(
        name="Reimbursement Agent",
        description="This agent handles the reimbursement process for the employees given the amount and purpose of the reimbursement.",
        url=f"http://{host}:{port}/",
        version="1.0.0",
        defaultInputModes=ReimbursementAgent.SUPPORTED_CONTENT_TYPES,
        defaultOutputModes=ReimbursementAgent.SUPPORTED_CONTENT_TYPES,
        capabilities=capabilities,
        skills=[skill],
    )
    server = A2AServer(
        agent_card=agent_card,
        task_manager=AgentTaskManager(agent=ReimbursementAgent()),
        host=host,
        port=port,
    )
    server.start()
if __name__ == "__main__":
    main()

