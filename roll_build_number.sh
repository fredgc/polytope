#!/bin/bash
set -e

# Find and increment the version number.
if [[ "$1" == "--release" ]]; then
  perl -i -pe 's/^(version:\s+\d+\.\d+\.)(\d+)\+(\d+)$/$1.($2+1)."+0"/e' pubspec.yaml
else
  perl -i -pe 's/^(version:\s+\d+\.\d+\.\d+\+)(\d+)$/$1.($2+1)/e' pubspec.yaml
fi

# Extract the new version info
version=$(grep '^version: ' pubspec.yaml | sed 's/version: //')
v_num=$(echo "$version" | cut -d'+' -f1)
echo "Rolling version to $version"

# Update web/version.json
cat <<EOF > web/version.json
{
  "version": "$version"
}
EOF

make ASSETS

echo "GREEN: Version is now $version"
