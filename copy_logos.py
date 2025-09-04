#!/usr/bin/env python3
import shutil
import os

# Source files
source_horizontal = '/hologram/data/project/lets_build_planner/.prompt_attachments/6aa22435-e203-4eed-92f4-45286987141e.png'
source_vertical = '/hologram/data/project/lets_build_planner/.prompt_attachments/3ee0379e-1828-44a6-b937-e3729e066530.png'

# Destination files
dest_horizontal = '/hologram/data/project/lets_build_planner/assets/images/logo_horizontal.png'
dest_vertical = '/hologram/data/project/lets_build_planner/assets/images/logo_vertical.png'

try:
    # Copy horizontal logo
    shutil.copy2(source_horizontal, dest_horizontal)
    print(f"Successfully copied horizontal logo to {dest_horizontal}")
    
    # Copy vertical logo
    shutil.copy2(source_vertical, dest_vertical)
    print(f"Successfully copied vertical logo to {dest_vertical}")
    
    print("All logo files copied successfully!")
    
except Exception as e:
    print(f"Error copying files: {e}")