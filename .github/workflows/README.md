# GitHub Actions Workflow

This repository uses GitHub Actions to automatically build and push multi-architecture Docker images to GitHub Container Registry (GHCR) using **native runners** for maximum speed.

## Workflow Features

- **🚀 Native Builds**: Uses `ubuntu-24.04` for AMD64 and `ubuntu-24.04-arm` for ARM64
- **⚡ Parallel Execution**: Builds both architectures simultaneously for speed
- **🛑 Smart Cancellation**: Automatically cancels old runs when new pushes happen
- **🔒 Automatic Authentication**: Uses `GITHUB_TOKEN` for secure access to GHCR
- **💾 Smart Caching**: Architecture-specific GitHub Actions cache
- **🏷️ Architecture-Specific Tags**: Creates detailed tags with all version information
- **📦 Manifest Creation**: Creates multi-arch manifests for seamless platform detection

## Build Architecture

### Job Structure
```yaml
jobs:
  build-amd64:     # Runs on ubuntu-24.04 (native x86_64)
  build-arm64:     # Runs on ubuntu-24.04-arm (native aarch64) 
  verify-build:    # Reports build completion
```

### Performance Benefits
- **No Emulation**: Native builds are ~10x faster than emulated cross-compilation
- **Parallel Execution**: Both architectures build simultaneously
- **Optimized Caching**: Separate cache scopes for each architecture
- **Smart Cancellation**: Old builds are cancelled when new commits are pushed

### Concurrency Control
The workflow uses GitHub's concurrency feature to prevent resource waste:

```yaml
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true
```

**How it works:**
- **Same branch/PR**: New push cancels the old build
- **Different branches**: Builds run independently  
- **Tags**: Each tag gets its own build (no cancellation)
- **Resource savings**: No wasted compute time on outdated code

## Generated Tags

The workflow generates two architecture-specific tags with multi-arch manifests:

```
ghcr.io/manticoresoftware/rust-min-libc:amd64-rust1.86.0-glibc2.17-openssl1.0.1u
ghcr.io/manticoresoftware/rust-min-libc:aarch64-rust1.86.0-glibc2.28-openssl1.1.1w
```

**Note**: Each tag works on both platforms - Docker automatically selects the correct architecture via the manifest.

## Triggers

### Automatic Triggers
- Push to `main` or `master` branch
- Git tags starting with `v*` (e.g., `v1.0.0`)
- Pull requests (build only, no push)

### Manual Trigger
1. Go to **Actions** tab in GitHub repository
2. Select **"Build and Push Multi-Architecture Docker Images"**
3. Click **"Run workflow"**
4. Select branch and confirm

## Configuration

All versions and settings are configured in the workflow environment variables:

```yaml
env:
  REGISTRY: ghcr.io
  IMAGE_NAME: manticoresoftware/rust-min-libc
  RUST_VERSION: "1.86.0"
  AMD64_GLIBC_VERSION: "2.17"
  AMD64_OPENSSL_VERSION: "1.0.1u"
  ARM64_GLIBC_VERSION: "2.28"
  ARM64_OPENSSL_VERSION: "1.1.1w"
```

## Authentication Options

The workflow supports two authentication methods:

### Option 1: GitHub Token (Default)
Uses the automatic `GITHUB_TOKEN` provided by GitHub Actions:
- ✅ **No setup required**
- ✅ **Automatic permissions**
- ✅ **Secure by default**

### Option 2: Custom Credentials (Optional)
Uses custom GitHub Container Registry credentials via secrets:
- 🔧 **Setup required**: Add `GHCR_USER` and `GHCR_PASSWORD` secrets
- 🎯 **Use case**: Custom authentication requirements
- 🔐 **Fallback**: Falls back to GitHub token if not provided

**To use custom credentials:**
1. Go to repository **Settings** → **Secrets and variables** → **Actions**
2. Add `GHCR_USER` secret with your GitHub username
3. Add `GHCR_PASSWORD` secret with your GitHub personal access token

**Authentication verification:**
The workflow automatically verifies authentication and fails fast if login doesn't work.

## Making Package Public

After the first successful build, make the package public:

1. Go to: https://github.com/manticoresoftware/manticore/pkgs/container/rust-min-libc
2. Click **"Package settings"**
3. Scroll to **"Danger Zone"**
4. Click **"Change package visibility"**
5. Select **"Public"**

## Permissions

The workflow has the necessary permissions:
- `contents: read` - To read repository content
- `packages: write` - To push to GitHub Container Registry
- `id-token: write` - For enhanced security

No additional secrets or tokens are required - it uses the automatic `GITHUB_TOKEN`.