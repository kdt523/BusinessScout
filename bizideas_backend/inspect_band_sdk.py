import sys
import os

# Set up python path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

try:
    import band
    print("band package found:")
    print("Attributes:", dir(band))
    
    from band import Agent
    print("\nAgent class attributes:", dir(Agent))
    
    # Check if there are other modules or classes in band
    import pkgutil
    package = band
    for _, module_name, _ in pkgutil.iter_modules(package.__path__):
        print("Submodule:", module_name)
        try:
            mod = __import__("band." + module_name, fromlist=["*"])
            print(f"  {module_name} attributes:", dir(mod))
        except Exception as e:
            print(f"  Failed to import {module_name}: {e}")
except ImportError as e:
    print("band library not found:", e)
