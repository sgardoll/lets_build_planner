#!/bin/bash

# Copy logo files from .prompt_attachments to assets/images/
echo "Copying logo files to assets/images/..."

# Copy horizontal logo
cp "/hologram/data/project/lets_build_planner/.prompt_attachments/6aa22435-e203-4eed-92f4-45286987141e.png" "/hologram/data/project/lets_build_planner/assets/images/logo_horizontal.png"
if [ $? -eq 0 ]; then
    echo " Horizontal logo copied successfully"
else
    echo " Failed to copy horizontal logo"
fi

# Copy vertical logo
cp "/hologram/data/project/lets_build_planner/.prompt_attachments/3ee0379e-1828-44a6-b937-e3729e066530.png" "/hologram/data/project/lets_build_planner/assets/images/logo_vertical.png"
if [ $? -eq 0 ]; then
    echo " Vertical logo copied successfully"
else
    echo " Failed to copy vertical logo"
fi

echo "Logo copying completed!"
echo ""
echo "Files are now available at:"
echo "- /hologram/data/project/lets_build_planner/assets/images/logo_horizontal.png"
echo "- /hologram/data/project/lets_build_planner/assets/images/logo_vertical.png"