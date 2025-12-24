# Flat Debian Repository with GitHub Release Support

This repository is currently empty.

## Add Repository

```bash
echo "deb [trusted=yes] https://raw.githubusercontent.com/codingWiz-rick/my-deb-repo/main ./" | sudo tee /etc/apt/sources.list.d/my-repo.list
sudo apt update
```
