# Structured Debian Repository for aarch64/arm64

A properly structured APT repository for ARM64 packages with automatic GitHub release support for large files.

## Repository Structure

```
my-deb-repo/
├── dists/
│   └── stable/
│       ├── Release
│       └── main/
│           └── binary-arm64/
│               ├── Packages
│               ├── Packages.gz
│               └── Packages.bz2
└── pool/
    └── main/
        ├── a/
        │   └── package-a/
        │       └── package-a_1.0_arm64.deb
        ├── b/
        │   └── package-b/
        │       └── package-b_2.0_arm64.deb
        └── ...
```

## Add Repository

```bash
echo "deb [trusted=yes arch=arm64] https://raw.githubusercontent.com/codingWiz-rick/my-deb-repo/main stable main" | sudo tee /etc/apt/sources.list.d/my-repo.list
sudo apt update
```

## Install Packages

```bash
sudo apt install <package-name>
```

## Features

- ✅ Proper Debian repository structure
- ✅ ARM64/aarch64 architecture only
- ✅ Organized pool directory by package name
- ✅ Automatic GitHub Releases for files >100MB
- ✅ Seamless APT integration
- ✅ No manual downloads required

## How It Works

Small packages (<100MB) are stored in the `pool/` directory and committed to Git. Large packages (>100MB) are automatically uploaded to GitHub Releases and their download URLs are added to the repository index. When you run `apt install`, APT automatically downloads large packages from GitHub Releases transparently.
