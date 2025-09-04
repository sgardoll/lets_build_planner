#!/usr/bin/env python3
import shutil
import os

def copy_logo_files():
    # Define source and destination paths
    copies = [
        {
            'src': '/hologram/data/project/lets_build_planner/.prompt_attachments/6aa22435-e203-4eed-92f4-45286987141e.png',
            'dst': '/hologram/data/project/lets_build_planner/assets/images/logo_horizontal.png',
            'name': 'horizontal logo'
        },
        {
            'src': '/hologram/data/project/lets_build_planner/.prompt_attachments/3ee0379e-1828-44a6-b937-e3729e066530.png',
            'dst': '/hologram/data/project/lets_build_planner/assets/images/logo_vertical.png',
            'name': 'vertical logo'
        }
    ]
    
    success_count = 0
    
    for copy_op in copies:
        try:
            # Check if source file exists
            if not os.path.exists(copy_op['src']):
                print(f"Error: Source file {copy_op['src']} does not exist")
                continue
            
            # Ensure destination directory exists
            dst_dir = os.path.dirname(copy_op['dst'])
            if not os.path.exists(dst_dir):
                os.makedirs(dst_dir, exist_ok=True)
                print(f"Created directory: {dst_dir}")
            
            # Copy the file
            shutil.copy2(copy_op['src'], copy_op['dst'])
            print(f"✓ Successfully copied {copy_op['name']} to {copy_op['dst']}")
            success_count += 1
            
        except Exception as e:
            print(f"✗ Error copying {copy_op['name']}: {e}")
    
    print(f"\nCopied {success_count} out of {len(copies)} logo files successfully!")
    
    if success_count == len(copies):
        print("All logo files are now available in the assets/images/ directory for your Flutter app.")

if __name__ == "__main__":
    copy_logo_files()