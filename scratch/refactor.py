import os

def replace_in_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    # Replacements
    replacements = {
        'SyncUpTheme.primary': 'context.colors.primary',
        'SyncUpTheme.primaryDark': 'context.colors.primaryDark',
        'SyncUpTheme.primaryLight': 'context.colors.primaryLight',
        'SyncUpTheme.accent': 'context.colors.accent',
        'SyncUpTheme.textPrimary': 'context.colors.textPrimary',
        'SyncUpTheme.textSecondary': 'context.colors.textSecondary',
        'SyncUpTheme.surface': 'context.colors.surface',
        'SyncUpTheme.background': 'context.colors.background',
        'SyncUpTheme.border': 'context.colors.border',
        'SyncUpTheme.divider': 'context.colors.divider',
        'SyncUpTheme.zenGreen': 'context.colors.zenGreen',
        'SyncUpTheme.zenGreenLight': 'context.colors.zenGreenLight',
        'SyncUpTheme.peach': 'context.colors.peach',
        'SyncUpTheme.peachLight': 'context.colors.peachLight',
    }

    new_content = content
    for old, new in replacements.items():
        new_content = new_content.replace(old, new)

    if new_content != content:
        # Check if we need to import sync_up_colors.dart
        if 'context.colors' in new_content and 'sync_up_colors.dart' not in new_content:
            # We must import it.
            # Try to find last import
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
