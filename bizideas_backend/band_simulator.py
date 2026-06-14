import asyncio
import json
import logging
from datetime import datetime
from typing import Dict, List, Any

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("BandSimulator")

class Message:
    def __init__(self, sender: str, role: str, content: str, msg_type: str = "text", data: Dict[str, Any] = None):
        self.id = f"msg_{int(datetime.utcnow().timestamp() * 1000)}"
        self.sender = sender
        self.role = role  # "agent" or "user"
        self.content = content
        self.timestamp = datetime.utcnow().isoformat() + "Z"
        self.type = msg_type  # "text", "status", "data", "json"
        self.data = data or {}

    def to_dict(self) -> Dict[str, Any]:
        return {
            "id": self.id,
            "sender": self.sender,
            "role": self.role,
            "content": self.content,
            "timestamp": self.timestamp,
            "type": self.type,
            "data": self.data
        }

class BandRoom:
    def __init__(self, room_id: str):
        self.room_id = room_id
        self.messages: List[Message] = []
        self.participants: List[str] = ["User"]
        self.listeners: List[asyncio.Queue] = []
        self.created_at = datetime.utcnow().isoformat() + "Z"

    async def add_participant(self, agent_name: str):
        if agent_name not in self.participants:
            self.participants.append(agent_name)
            await self.post_status(f"@{agent_name} has joined the room.")

    async def post_message(self, message: Message):
        self.messages.append(message)
        logger.info(f"[Room {self.room_id}] {message.sender}: {message.content[:60]}...")
        
        # Broadcast to all active listeners
        msg_dict = message.to_dict()
        for queue in list(self.listeners):
            try:
                await queue.put(msg_dict)
            except Exception as e:
                logger.error(f"Error putting message to listener: {e}")

    async def post_text(self, sender: str, role: str, content: str, data: Dict[str, Any] = None):
        msg = Message(sender=sender, role=role, content=content, msg_type="text", data=data)
        await self.post_message(msg)
        return msg

    async def post_status(self, content: str):
        msg = Message(sender="System", role="system", content=content, msg_type="status")
        await self.post_message(msg)
        return msg

    async def post_orchestration_event(
        self,
        stage: str,
        content: str,
        from_agent: str = "",
        to_agents: List[str] = None,
        state: str = "active",
        data: Dict[str, Any] = None,
    ):
        payload = {
            "stage": stage,
            "from_agent": from_agent,
            "to_agents": to_agents or [],
            "state": state,
            **(data or {}),
        }
        msg = Message(
            sender="Band Mesh",
            role="system",
            content=content,
            msg_type="orchestration",
            data=payload,
        )
        await self.post_message(msg)
        return msg

    async def post_data(self, sender: str, content: str, data: Dict[str, Any]):
        msg = Message(sender=sender, role="agent", content=content, msg_type="data", data=data)
        await self.post_message(msg)
        return msg

    def get_history(self) -> List[Dict[str, Any]]:
        return [msg.to_dict() for msg in self.messages]

class BandSimulator:
    def __init__(self):
        self.rooms: Dict[str, BandRoom] = {}
        self._lock = asyncio.Lock()

    async def get_or_create_room(self, room_id: str) -> BandRoom:
        async with self._lock:
            if room_id not in self.rooms:
                self.rooms[room_id] = BandRoom(room_id)
                logger.info(f"Created new Band Room: {room_id}")
            return self.rooms[room_id]

    async def subscribe(self, room_id: str) -> asyncio.Queue:
        room = await self.get_or_create_room(room_id)
        queue = asyncio.Queue()
        room.listeners.append(queue)
        logger.info(f"New client subscribed to room {room_id}. Total listeners: {len(room.listeners)}")
        return queue

    async def unsubscribe(self, room_id: str, queue: asyncio.Queue):
        if room_id in self.rooms:
            room = self.rooms[room_id]
            if queue in room.listeners:
                room.listeners.remove(queue)
                logger.info(f"Client unsubscribed from room {room_id}. Remaining listeners: {len(room.listeners)}")

# Global instance of simulator
simulator = BandSimulator()
