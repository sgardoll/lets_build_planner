#!/usr/bin/env python3
import shutil
import os

source = "/hologram/data/project/lets_build_planner/.prompt_attachments/5ad176e9-3498-4a04-a88d-6e02494bcba7.png"
destination = "/hologram/data/project/lets_build_planner/assets/images/logo.png"

# Ensure destination directory exists
os.makedirs(os.path.dirname(destination), exist_ok=True)

# Copy the file
shutil.copy2(source, destination)
print(f"Successfully copied {source} to {destination}")