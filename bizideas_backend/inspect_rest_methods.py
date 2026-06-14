import sys
import os

sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from band.client.rest import RestClient

client = RestClient(api_key="dummy", base_url="https://app.band.ai")

print("=== RestClient.agent_api_chats ===")
print(dir(client.agent_api_chats))

print("\n=== RestClient.agent_api_messages ===")
print(dir(client.agent_api_messages))

print("\n=== RestClient.agent_api_participants ===")
print(dir(client.agent_api_participants))

print("\n=== RestClient.human_api_chats ===")
print(dir(client.human_api_chats))
