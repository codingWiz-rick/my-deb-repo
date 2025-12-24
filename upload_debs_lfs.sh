#!/bin/bash
# Modified script - adds GitHub release URLs directly to Packages file

DEB_SOURCE_DIR="$HOME/termux-packages/output"
REPO_DIR="$HOME/my-deb-repo"
GITHUB_REPO="codingWiz-rick/my-deb-repo"
SIZE_LIMIT=$((100 * 1024 * 1024))

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

cd "$REPO_DIR" || exit 1
git pull origin main

LARGE_FILES=()
RELEASE_TAG="debs-$(date +%Y%m%d-%H%M%S)"
TEMP_PACKAGES="/tmp/packages_temp.$$"

# Process small files normally
find "$DEB_SOURCE_DIR" -name "*.deb" | while read -r deb_file; do
    filename=$(basename "$deb_file")
    file_size=$(stat -c%s "$deb_file" 2>/dev/null || stat -f%z "$deb_file" 2>/dev/null)
    
    if [ "$file_size" -le "$SIZE_LIMIT" ]; then
        dest_file="$REPO_DIR/$filename"
        if [ -f "$dest_file" ]; then
            source_time=$(stat -c %Y "$deb_file" 2>/dev/null || stat -f %m "$deb_file" 2>/dev/null)
            dest_time=$(stat -c %Y "$dest_file" 2>/dev/null || stat -f %m "$dest_file" 2>/dev/null)
            
            if [ "$source_time" -gt "$dest_time" ]; then
                echo -e "${YELLOW}Updating: $filename${NC}"
                cp "$deb_file" "$dest_file"
                git add "$filename"
            fi
        else
            echo -e "${GREEN}Adding: $filename${NC}"
            cp "$deb_file" "$dest_file"
            git add "$filename"
        fi
    else
        echo -e "${YELLOW}Large file: $filename${NC}"
        echo "$deb_file" >> /tmp/large_files.txt
    fi
done

# Generate Packages for small files
echo -e "\n${YELLOW}Generating Packages index...${NC}"
dpkg-scanpackages -m . /dev/null > "$TEMP_PACKAGES"

# Upload large files to GitHub releases
if [ -f /tmp/large_files.txt ]; then
    echo -e "\n${YELLOW}Creating GitHub release for large files...${NC}"
    
    if command -v gh &> /dev/null; then
        gh release create "$RELEASE_TAG" \
            --title "Large Packages - $(date '+%Y-%m-%d %H:%M')" \
            --notes "Large .deb files (>100MB)" \
            --repo "$GITHUB_REPO"
        
        # Upload each large file and add to Packages
        while IFS= read -r deb_file; do
            filename=$(basename "$deb_file")
            echo -e "${YELLOW}Uploading: $filename${NC}"
            
            gh release upload "$RELEASE_TAG" "$deb_file" \
                --repo "$GITHUB_REPO" --clobber
            
            # Generate package info for large file
            echo -e "\n" >> "$TEMP_PACKAGES"
            dpkg-deb -f "$deb_file" | sed 's/^//' >> "$TEMP_PACKAGES"
            
            # Add GitHub release URL as Filename
            RELEASE_URL="https://github.com/$GITHUB_REPO/releases/download/$RELEASE_TAG/$filename"
            echo "Filename: $RELEASE_URL" >> "$TEMP_PACKAGES"
            
            file_size=$(stat -c%s "$deb_file" 2>/dev/null || stat -f%z "$deb_file" 2>/dev/null)
            echo "Size: $file_size" >> "$TEMP_PACKAGES"
            
            md5=$(md5sum "$deb_file" | cut -d' ' -f1)
            echo "MD5sum: $md5" >> "$TEMP_PACKAGES"
            
            sha256=$(sha256sum "$deb_file" | cut -d' ' -f1)
            echo "SHA256: $sha256" >> "$TEMP_PACKAGES"
            
        done < /tmp/large_files.txt
        
        rm /tmp/large_files.txt
    fi
fi

# Finalize Packages file
mv "$TEMP_PACKAGES" Packages
gzip -9c Packages > Packages.gz
bzip2 -9fk Packages

# Generate Release file
cat > Release << EOF
Origin: my-deb-repo
Label: my-deb-repo
Suite: stable
Codename: stable
Date: $(date -Ru)
Architectures: all amd64 arm64 armhf i386
Components: ./
Description: Flat Debian Repository with GitHub Release Support
EOF

echo "MD5Sum:" >> Release
for file in Packages Packages.gz Packages.bz2; do
    if [ -f "$file" ]; then
        size=$(stat -c%s "$file" 2>/dev/null || stat -f%z "$file" 2>/dev/null)
        md5=$(md5sum "$file" | cut -d' ' -f1)
        echo " $md5 $size $file" >> Release
    fi
done

echo "SHA256:" >> Release
for file in Packages Packages.gz Packages.bz2; do
    if [ -f "$file" ]; then
        size=$(stat -c%s "$file" 2>/dev/null || stat -f%z "$file" 2>/dev/null)
        sha256=$(sha256sum "$file" | cut -d' ' -f1)
        echo " $sha256 $size $file" >> Release
    fi
done

git add Packages Packages.gz Packages.bz2 Release

# Update README
cat > README.md << 'EOF'
# Flat Debian Repository with GitHub Release Support

Small packages (<100MB) are in the repo root. Large packages are automatically downloaded from GitHub releases.

## Add Repository

```bash
echo "deb [trusted=yes] https://raw.githubusercontent.com/codingWiz-rick/my-deb-repo/main ./" | sudo tee /etc/apt/sources.list.d/my-repo.list
sudo apt update
```

## Install Any Package

```bash
sudo apt install <package-name>
```

Large packages are automatically downloaded from GitHub releases - **no manual steps required!**
EOF

git add README.md

if ! git diff --cached --quiet; then
    git commit -m "Update packages - $(date '+%Y-%m-%d %H:%M')"
    git push origin main
    echo -e "\n${GREEN}Repository updated successfully!${NC}"
else
    echo -e "\n${YELLOW}No changes to commit${NC}"
fi
