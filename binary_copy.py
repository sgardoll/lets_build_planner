#!/usr/bin/env python3

def copy_binary_file(src_path, dst_path):
    try:
        with open(src_path, 'rb') as src_file:
            with open(dst_path, 'wb') as dst_file:
                dst_file.write(src_file.read())
        return True
    except Exception as e:
        print(f"Error copying {src_path} to {dst_path}: {e}")
        return False

# Copy horizontal logo
src1 = '/hologram/data/project/lets_build_planner/.prompt_attachments/6aa22435-e203-4eed-92f4-45286987141e.png'
dst1 = '/hologram/data/project/lets_build_planner/assets/images/logo_horizontal.png'

# Copy vertical logo  
src2 = '/hologram/data/project/lets_build_planner/.prompt_attachments/3ee0379e-1828-44a6-b937-e3729e066530.png'
dst2 = '/hologram/data/project/lets_build_planner/assets/images/logo_vertical.png'

if copy_binary_file(src1, dst1):
    print(f"✓ Horizontal logo copied successfully to {dst1}")
else:
    print("✗ Failed to copy horizontal logo")

if copy_binary_file(src2, dst2):
    print(f"✓ Vertical logo copied successfully to {dst2}")  
else:
    print("✗ Failed to copy vertical logo")
    
print("Logo copying operation completed!")