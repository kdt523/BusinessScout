import sys
import os

sys.path.append(os.path.dirname(os.path.abspath(__file__)))

import band.client.rest
print("band.client.rest attributes:", dir(band.client.rest))

# Let's inspect modules or classes inside band.client.rest
try:
    from band.client.rest import RestClient
    print("\nRestClient class attributes:", dir(RestClient))
except ImportError as e:
    print("RestClient import failed:", e)

# Also check band.platform.link
try:
    from band.platform.link import BandLink
    print("\nBandLink class attributes:", dir(BandLink))
except ImportError as e:
    print("BandLink import failed:", e)
