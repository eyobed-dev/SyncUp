import os

def replace_in_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    # Replacing Colors.white with context.colors.surface globally
    new_content = content.replace('Colors.white', 'context.colors.surface')

    if new_content != content:
        with open(filepath, 'w') as f:
            f.write(new_content)
        print(f"Updated {filepath}")

def main():
    lib_dir = '/home/eyobed/Documents/School/BUT/Semester 2/UXIa/Projects/SyncUp/lib/widgets'
    for root, dirs, files in os.walk(lib_dir):
        for file in files:
            if file.endswith('.dart'):
                replace_in_file(os.path.join(root, file))
    
    lib_dir = '/home/eyobed/Documents/School/BUT/Semester 2/UXIa/Projects/SyncUp/lib/screens'
    for root, dirs, files in os.walk(lib_dir):
        for file in files:
            if file.endswith('.dart'):
                replace_in_file(os.path.join(root, file))

if __name__ == '__main__':
    main()
