#!/bin/bash
set -e

echo "🚀 Building Flutter Web..."
flutter build web

echo "📦 Committing build output to 'release' branch..."
# Temporarily force-add the ignored build/web directory to the Git index
git add -f build/web

# Create a Git tree object from the build/web directory
TREE=$(git write-tree --prefix=build/web)

# Create a new commit referencing the tree object
COMMIT=$(git commit-tree $TREE -m "Deploy web build $(date)")

# Update the local 'release' branch to point to this new commit
git update-ref refs/heads/release $COMMIT

# Push the release branch to the remote repository, overwriting the previous deploy
git push origin release --force

# Remove build/web from the Git index so it stays ignored on the main branch
git rm --cached -r build/web > /dev/null

echo "✅ Success! The compiled web build is now pushed to the 'release' branch."
echo ""
echo "  git clone -b release https://github.com/eyobed-dev/SyncUp.git ."
echo "  git fetch && git checkout release && git reset --hard origin/release"
