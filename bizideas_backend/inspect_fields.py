import sys
import os

sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from band.client.rest import ChatRoomRequest, ChatMessageRequest, ChatMessageRequestMentionsItem

print("ChatRoomRequest fields:")
for name, field in ChatRoomRequest.model_fields.items():
    print(f"  {name}: {field.annotation} (default: {field.default})")

print("\nChatMessageRequest fields:")
for name, field in ChatMessageRequest.model_fields.items():
    print(f"  {name}: {field.annotation} (default: {field.default})")

print("\nChatMessageRequestMentionsItem fields:")
for name, field in ChatMessageRequestMentionsItem.model_fields.items():
    print(f"  {name}: {field.annotation} (default: {field.default})")
