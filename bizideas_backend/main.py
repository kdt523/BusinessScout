import os
import uuid
import asyncio
import logging
import json
from dotenv import load_dotenv
load_dotenv()

from fastapi import FastAPI, HTTPException, Request, Query
from fastapi.responses import StreamingResponse, FileResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional, Dict, Any

from band_simulator import simulator, Message
from agents.orchestrator import OrchestratorAgent
from utils.market_profile import build_market_profile

logger = logging.getLogger("BizIdeasAPI")

# USE_SIMULATOR=true  -> agents run in-process and post to the local Band Room
#                        simulator (self-contained demo, no external account).
# USE_SIMULATOR=false -> the four agents run as real Band participants via
#                        `python band_runner.py`, collaborating over a live Band
#                        room. The bridge mirrors those messages back into the
#                        simulator rooms so this server's SSE stream (and the
#                        Flutter visualization) keeps working unchanged.
USE_SIMULATOR = os.getenv("USE_SIMULATOR", "true").strip().lower() in ("1", "true", "yes")
ENGINE_NAME = "Band Room Simulator" if USE_SIMULATOR else "Live Band Platform"

# Initialize FastAPI
app = FastAPI(
    title="BizIdeas Backend API",
    description="Multi-agent business feasibility scouting backend powered by local Band Room simulation",
    version="1.0.0"
)

# Enable CORS for Flutter app integration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Define models
class AnalysisRequest(BaseModel):
    business_type: str = "Coffee Shop"
    city: str = "New York, United States"
    room_id: Optional[str] = None
    user_locale: Optional[str] = None
    user_country: Optional[str] = None

class MessagePayload(BaseModel):
    sender: str
    role: str
    content: str
    type: str = "text"
    data: Optional[Dict[str, Any]] = None

@app.get("/")
async def root():
    return {
        "app": "BizIdeas Multi-Agent API",
        "status": "online",
        "engine": ENGINE_NAME,
        "use_simulator": USE_SIMULATOR,
    }

@app.post("/api/rooms/{room_id}/messages")
async def add_message(room_id: str, payload: MessagePayload):
    room = await simulator.get_or_create_room(room_id)
    if payload.type == "status":
        await room.post_status(payload.content)
    elif payload.type == "orchestration":
        await room.post_orchestration_event(
            stage=payload.data.get("stage") if payload.data else "",
            content=payload.content,
            from_agent=payload.data.get("from_agent") if payload.data else "",
            to_agents=payload.data.get("to_agents") if payload.data else [],
            state=payload.data.get("state", "active") if payload.data else "active",
            data=payload.data
        )
    elif payload.type == "data":
        await room.post_data(payload.sender, payload.content, payload.data)
    elif payload.type == "participant":
        await room.add_participant(payload.sender)
    else:
        await room.post_text(payload.sender, payload.role, payload.content, payload.data)
    return {"status": "success"}

@app.post("/api/rooms/create")
async def create_room(req: AnalysisRequest):
    room_id = req.room_id or str(uuid.uuid4())
    
    if not USE_SIMULATOR:
        try:
            from band.client.rest import RestClient, ChatRoomRequest, ChatMessageRequest, ChatMessageRequestMentionsItem, ParticipantRequest
            orchestrator_key = os.getenv("BAND_ORCHESTRATOR_KEY")
            orchestrator_id = os.getenv("BAND_ORCHESTRATOR_ID")
            orchestrator_handle = os.getenv("BAND_ORCHESTRATOR_HANDLE", "@zrald/main").lstrip("@")
            
            scout_key = os.getenv("BAND_LOCATION_SCOUT_KEY")
            scout_id = os.getenv("BAND_LOCATION_SCOUT_ID")
            
            rest_url = os.getenv("BAND_REST_URL", os.getenv("THENVOI_REST_URL", "https://app.band.ai"))
            
            # 1. Create room as Orchestrator
            orch_client = RestClient(api_key=orchestrator_key, base_url=rest_url)
            chat_resp = orch_client.agent_api_chats.create_agent_chat(chat=ChatRoomRequest())
            room_id = chat_resp.data.id
            logger.info(f"Created live Band room: {room_id}")
            
            # 2. Add Location Scout to the room
            orch_client.agent_api_participants.add_agent_chat_participant(
                chat_id=room_id,
                participant=ParticipantRequest(participant_id=scout_id)
            )
            logger.info(f"Added Location Scout {scout_id} to room {room_id}")
            
            # 3. Post the initial user brief from the Location Scout's identity (mentioning Orchestrator)
            scout_client = RestClient(api_key=scout_key, base_url=rest_url)
            brief_content = f"@{orchestrator_handle} start a {req.business_type} in {req.city}"
            scout_client.agent_api_messages.create_agent_chat_message(
                chat_id=room_id,
                message=ChatMessageRequest(
                    content=brief_content,
                    mentions=[
                        ChatMessageRequestMentionsItem(
                            id=orchestrator_id,
                            handle=orchestrator_handle
                        )
                    ]
                )
            )
            logger.info(f"Seeded live Band room {room_id} with initial brief from Location Scout: {brief_content}")
        except Exception as e:
            logger.error(f"Failed to create/seed live Band room: {e}")
            raise HTTPException(status_code=500, detail=f"Failed to create/seed live Band room: {e}")
            
    room = await simulator.get_or_create_room(room_id)
    
    # Reset room state if it already existed to allow fresh runs
    room.messages = []
    
    # Log session start
    await room.post_status(f"Starting Multi-Agent Feasibility Study for '{req.business_type}' in '{req.city}'...")
    await room.post_orchestration_event(
        stage="CONNECT",
        content="Connecting to app.band.ai WebSocket...",
        from_agent="System",
        to_agents=["Band Mesh"],
        state="active"
    )
    
    await asyncio.sleep(0.4)
    await room.post_orchestration_event(
        stage="room_open",
        content="Band room opened. User brief was committed to the shared collaboration layer.",
        from_agent="User",
        to_agents=["Orchestrator"],
        state="active",
        data={
            "business_type": req.business_type,
            "city": req.city,
            "handoff": "User brief -> Orchestrator",
        },
    )
    
    market_profile = await build_market_profile(
        req.city,
        user_locale=req.user_locale,
        user_country=req.user_country,
    )
    context = {
        "business_type": req.business_type,
        "city": req.city,
        "market_profile": market_profile.to_dict(),
    }

    if USE_SIMULATOR:
        # Self-contained demo: run the Orchestrator in-process; it fans out to
        # the other agents and everything posts to the simulator room.
        orchestrator = OrchestratorAgent()
        asyncio.create_task(orchestrator.run(room, context))
    else:
        # Live Band mode: seed context in local thread state if running runner in same process
        # (though typically runner runs in band_runner.py, it's good to sync)
        try:
            from band_agents import get_room_state
            state = await get_room_state(room_id)
            state.context = dict(context)
        except Exception as e:
            logger.warning(f"Could not seed local thread state for live room: {e}")
            
        await room.post_text(
            sender="User",
            role="user",
            content=f"@Orchestrator start a {req.business_type} in {req.city}",
            data={"business_type": req.business_type, "city": req.city},
        )

    return {
        "room_id": room_id,
        "status": "initiated",
        "engine": ENGINE_NAME,
        "message": f"Multi-agent session started. Listen to stream at /api/rooms/{room_id}/stream"
    }

@app.get("/api/rooms/{room_id}/messages")
async def get_messages(room_id: str):
    if room_id not in simulator.rooms:
        raise HTTPException(status_code=404, detail="Room not found")
    room = simulator.rooms[room_id]
    return room.get_history()

@app.get("/api/rooms/{room_id}/stream")
async def stream_room_events(room_id: str, request: Request):
    """
    Streams live messages posted to the Band Room using Server-Sent Events (SSE).
    """
    if room_id not in simulator.rooms:
        await simulator.get_or_create_room(room_id)
        
    queue = await simulator.subscribe(room_id)
    
    async def event_generator():
        try:
            # First, send current history to client so they catch up instantly
            room = simulator.rooms[room_id]
            for msg in room.get_history():
                yield f"data: {json_dumps(msg)}\n\n"
                await asyncio.sleep(0.05) # Prevent flooding
                
            while True:
                # Disconnect if client leaves
                if await request.is_disconnected():
                    logger.info(f"Client disconnected from stream for room {room_id}")
                    break
                
                try:
                    # Non-blocking wait for new messages
                    msg = await asyncio.wait_for(queue.get(), timeout=1.0)
                    yield f"data: {json_dumps(msg)}\n\n"
                    queue.task_done()
                except asyncio.TimeoutError:
                    # Send keep-alive ping
                    yield ": ping\n\n"
                    
        except asyncio.CancelledError:
            logger.info(f"SSE stream task cancelled for room {room_id}")
        finally:
            await simulator.unsubscribe(room_id, queue)

    return StreamingResponse(
        event_generator(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
            "X-Accel-Buffering": "no"
        }
    )

@app.get("/api/rooms/{room_id}/pdf")
async def download_pdf(room_id: str):
    pdf_path = os.path.join("static", "reports", f"{room_id}_business_plan.pdf")
    if not os.path.exists(pdf_path):
        raise HTTPException(
            status_code=404, 
            detail="Business plan PDF not generated yet. Please wait for the Business Planner agent to complete."
        )
    return FileResponse(
        path=pdf_path,
        media_type="application/pdf",
        filename=f"BizIdeas_{room_id}_Business_Plan.pdf"
    )

@app.get("/api/reports")
async def list_reports():
    reports_dir = os.path.join("static", "reports")
    if not os.path.exists(reports_dir):
        return []
    
    results = []
    for f in os.listdir(reports_dir):
        if f.endswith("_metadata.json"):
            try:
                with open(os.path.join(reports_dir, f), "r", encoding="utf-8") as file:
                    data = json.load(file)
                    results.append(data)
            except Exception as e:
                logger.error(f"Failed to read metadata file {f}: {e}")
                
    # Sort by timestamp descending
    results.sort(key=lambda x: x.get("timestamp", 0), reverse=True)
    return results

# Helper function
def json_dumps(data: Any) -> str:
    import json
    return json.dumps(data)

if __name__ == "__main__":
    import uvicorn
    # Load configuration
    port = int(os.getenv("PORT", 8000))
    host = os.getenv("HOST", "0.0.0.0")
    
    logging.getLogger("uvicorn").setLevel(logging.INFO)
    
    uvicorn.run("main:app", host=host, port=port, reload=True)
