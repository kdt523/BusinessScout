import asyncio
import logging
from typing import Any, Dict

logger = logging.getLogger("AgentTasks")


async def run_agent_safely(agent: Any, room: Any, context: Dict[str, Any]) -> None:
    try:
        await agent.run(room, context)
    except asyncio.CancelledError:
        logger.info("%s task cancelled for room %s", agent.name, room.room_id)
        raise
    except Exception as exc:
        logger.exception("%s failed for room %s", agent.name, room.room_id)
        await room.post_status(f"{agent.name} failed: {exc}")


def create_agent_task(agent: Any, room: Any, context: Dict[str, Any]) -> asyncio.Task:
    return asyncio.create_task(
        run_agent_safely(agent, room, context),
        name=f"{agent.name}:{room.room_id}",
    )
