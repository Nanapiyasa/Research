import os
import sys

# Check if a file
def check_path_exists(path: str, description: str = "File"):

    if not os.path.exists(path):
        print(f"-- {description} not found at path: {path}")
        sys.exit(1)
    print(f"-- {description} found at path: {path}")
