import os
import re

def replace_in_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    # Replacements
    properties = [
        'primary', 'primaryDark', 'primaryLight', 'accent',
        'textPrimary', 'textSecondary', 'surface', 'background',
        'border', 'divider', 'zenGreen', 'zenGreenLight', 'peach', 'peachLight',
        'cardShadow', 'cardShadowHover', 'modalShadow'
    ]

    new_content = content
    for prop in properties:
        pattern = r'SyncUpTheme\s*\.\s*' + prop
        replacement = r'context.colors.' + prop
        new_content = re.sub(pattern, replacement, new_content)

    if new_content != content:
        # Check if we need to import sync_up_colors.dart
        if 'context.colors' in new_content and 'sync_up_colors.dart' not in new_content:
            import_str = "import 'package:sync_up/theme/sync_up_colors.dart';\n"
            if 'import ' in new_content:
                last_import_idx = new_content.rfind("import '")
                end_of_line = new_content.find('\n', last_import_idx)
                new_content = new_content[:end_of_line+1] + import_str + new_content[end_of_line+1:]
            else:
                new_content = import_str + new_content

        with open(filepath, 'w') as f:
            f.write(new_content)
        print(f"Updated {filepath}")

def main():
    lib_dir = '/home/eyobed/Documents/School/BUT/Semester 2/UXIa/Projects/SyncUp/lib'
    for root, dirs, files in os.walk(lib_dir):
        for file in files:
            if file.endswith('.dart'):
                if file in ['sync_up_theme.dart', 'sync_up_colors.dart', 'agendrix_theme.dart', 'theme_controller.dart']:
                    continue
                replace_in_file(os.path.join(root, file))

if __name__ == '__main__':
    main()
