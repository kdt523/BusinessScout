import sys
import os

sys.path.append(os.path.dirname(os.path.abspath(__file__)))

# In inspect_signatures, we saw:
# ... -> thenvoi_rest.agent_api_chats.types.create_agent_chat_response.CreateAgentChatResponse
# Let's import it or check how the response is structured. We can import RestClient and see the response model.
from band.client.rest import RestClient

try:
    from thenvoi_rest.agent_api_chats.types.create_agent_chat_response import CreateAgentChatResponse
    print("CreateAgentChatResponse fields:")
    for name, field in CreateAgentChatResponse.model_fields.items():
        print(f"  {name}: {field.annotation}")
        
    # Also inspect Chat fields
    from thenvoi_rest.types.chat_room import ChatRoom
    print("\nChatRoom fields:")
    for name, field in ChatRoom.model_fields.items():
        print(f"  {name}: {field.annotation}")
except Exception as e:
    print("Failed to import or inspect:", e)
