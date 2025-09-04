import 'dart:io';

Future<void> main() async {
  final source = File('/hologram/data/project/lets_build_planner/.prompt_attachments/5ad176e9-3498-4a04-a88d-6e02494bcba7.png');
  final destination = File('/hologram/data/project/lets_build_planner/assets/images/logo.png');
  
  try {
    // Ensure the destination directory exists
    await destination.parent.create(recursive: true);
    
    // Copy the file
    await source.copy(destination.path);
    
    print('Logo copied successfully to ${destination.path}');
  } catch (e) {
    print('Error copying file: $e');
  }
}