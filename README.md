# Flat Debian Repository with GitHub Release Support

Small packages (<70MB) are in the repo root. Large packages are automatically downloaded from GitHub releases.

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
