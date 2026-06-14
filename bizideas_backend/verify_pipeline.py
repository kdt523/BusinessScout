import asyncio
import os
import sys

# Ensure backend directory is in path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

from band_simulator import BandRoom
from agents.orchestrator import OrchestratorAgent

async def run_pipeline_test():
    print("🚀 Initiating Multi-Agent Pipeline Verification...")
    
    # Create room
    room_id = "test_verification_room"
    room = BandRoom(room_id)
    pdf_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "static", "reports", f"{room_id}_business_plan.pdf")
    if os.path.exists(pdf_path):
        os.remove(pdf_path)
    
    # Set context
    context = {
        "business_type": "Specialty Coffee Shop",
        "city": "New York, United States"
    }

    # Listen to room messages via a subscriber queue to mock Flutter client streaming
    listeners_queue = asyncio.Queue()
    room.listeners.append(listeners_queue)

    # Define consumer task to print messages as they arrive
    async def message_consumer():
        try:
            while True:
                msg_dict = await listeners_queue.get()
                sender = msg_dict["sender"]
                role = msg_dict["role"]
                content = msg_dict["content"]
                msg_type = msg_dict["type"]
                
                print(f"\n[STREAM EVENT] Sender: {sender} ({role}) | Type: {msg_type}")
                print(f"Content:\n{content[:200]}...")
                if len(content) > 200:
                    print("... (truncated)")
                
                listeners_queue.task_done()
                
                if sender == "System" and "closed" in content:
                    break
        except asyncio.CancelledError:
            pass

    consumer_task = asyncio.create_task(message_consumer())

    # Trigger Orchestrator in background
    print("\n⚡ Kicking off Orchestrator Agent...")
    orchestrator = OrchestratorAgent()
    await orchestrator.run(room, context)
    
    # Wait for the agents to complete processing
    # (Since each agent schedules the next using asyncio.create_task, we wait)
    print("\n⏳ Waiting for multi-agent handoffs to complete...")
    
    # Wait up to 60 seconds for pipeline to finish
    completed = False
    for i in range(180):
        await asyncio.sleep(1.0)
        # Check if Business Planner has finished
        if any(msg["sender"] == "System" and "closed" in msg["content"] for msg in room.get_history()):
            print("\n✅ Multi-agent pipeline completed successfully!")
            completed = True
            break
    else:
        print("\n❌ Pipeline timed out before completion.")

    # Cancel consumer task
    consumer_task.cancel()
    await asyncio.gather(consumer_task, return_exceptions=True)

    # 4. Verify PDF output
    if os.path.exists(pdf_path):
        size_kb = os.path.getsize(pdf_path) / 1024
        print(f"\n✅ PDF Generated Successfully at: {pdf_path}")
        print(f"File Size: {size_kb:.2f} KB")
        return completed
    else:
        print(f"\n❌ PDF Generation Failed. File not found at: {pdf_path}")
        return False

if __name__ == "__main__":
    success = asyncio.run(run_pipeline_test())
    if success:
        sys.exit(0)
    else:
        sys.exit(1)
