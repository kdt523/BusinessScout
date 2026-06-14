import sys
import os
import inspect

sys.path.append(os.path.dirname(os.path.abspath(__file__)))

# Import ChatRoomRequest from the REST SDK
# In inspect_signatures output it showed the backend package is thenvoi_rest, which is likely aliased or imported via band
from band.client.rest import ChatRoomRequest
from band.client.rest import ChatMessageRequest, ChatMessageRequestMentionsItem

print("=== ChatRoomRequest inspect ===")
try:
    print(inspect.signature(ChatRoomRequest.__init__))
except Exception as e:
    print("Init signature failed:", e)

# Let's inspect fields
req = ChatRoomRequest()
print("ChatRoomRequest dir:", [attr for attr in dir(req) if not attr.startswith('_')])

print("\n=== ChatMessageRequest inspect ===")
req_msg = ChatMessageRequest(content="hello")
print("ChatMessageRequest dir:", [attr for attr in dir(req_msg) if not attr.startswith('_')])

print("\n=== ChatMessageRequestMentionsItem inspect ===")
try:
    print(inspect.signature(ChatMessageRequestMentionsItem.__init__))
except Exception as e:
    print("Init signature failed:", e)
