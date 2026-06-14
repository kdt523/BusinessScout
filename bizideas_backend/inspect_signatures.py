import sys
import os
import inspect

sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from band.client.rest import RestClient

client = RestClient(api_key="dummy", base_url="https://app.band.ai")

print("=== create_agent_chat Signature ===")
try:
    print(inspect.signature(client.agent_api_chats.create_agent_chat))
except Exception as e:
    print("Failed to get signature:", e)

print("\n=== create_agent_chatDocstring ===")
print(client.agent_api_chats.create_agent_chat.__doc__)

print("=== create_agent_chat_message Signature ===")
try:
    print(inspect.signature(client.agent_api_messages.create_agent_chat_message))
except Exception as e:
    print("Failed to get signature:", e)

print("\n=== create_agent_chat_message Docstring ===")
print(client.agent_api_messages.create_agent_chat_message.__doc__)
