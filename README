# Development Container Environment

A fully-featured development container based on Fedora, providing a complete IDE setup with OpenVSCode Server and various development tools. This container is designed for cloud-native development with built-in support for Rust, Node.js, Java, and container orchestration tools.

## Features

### IDE & Editor Support
- OpenVSCode Server (v1.93.1)
- NvChad (Neovim configuration)
- Pre-installed VS Code extensions for:
  - Rust development
  - YAML editing
  - Tailwind CSS
  - TOML support
  - WakaTime tracking
  - Jupyter notebooks
  - AI assistance (Continue.ai)

### Programming Languages & Runtimes
- Rust (latest stable)
  - cargo-watch
  - diesel_cli (with PostgreSQL and MySQL support)
- Node.js
- Bun runtime
- Java (Latest OpenJDK)
- Python 3
- GCC & Clang compilers

### Cloud & Container Tools
- Podman
- OKD Client (v4.13.0)
- Helm
- Container development tools

### Database Support
- MariaDB client and development libraries
- PostgreSQL client and development libraries
- Diesel CLI with MySQL and PostgreSQL support

### Additional Tools
- Git
- ImageMagick
- FFmpeg
- OpenSSL
- Ripgrep
- Starship prompt

## Usage

### Building the Container

```bash
podman build -t dev-environment .
# or using Docker
docker build -t dev-environment .
```

### Running the Container

```bash
podman run -d \
  -p 3000:3000 \
  -v "${PWD}:/home/codium/workspace" \
  --name dev-env \
  dev-environment
```

After starting the container, access the VS Code Server interface at `http://localhost:3000`

### Environment Variables

- `PORT`: Web interface port (default: 3000)
- `HOME`: User home directory (default: /home/codium)
- `EDITOR`/`VISUAL`: Set to 'code' for VS Code Server
- `LANG` and `LC_ALL`: Set to C.UTF-8

## Security Considerations

- The container runs as a non-root user (UID 1001)
- Supports OpenShift's security model (random UID with GID 0)
- Compatible with rootless container deployments
- Supported UID:GID combinations:
  - UID=1001 && GID=0
  - UID=<any> && GID=0
  - UID=1001 && GID=<any>

## Customization

### Shell Configuration
- Uses Starship prompt for enhanced terminal experience
- Includes bash completion for various tools:
  - OKD (oc)
  - Helm
  - Diesel
  - Rustup
  - Cargo

### Font Support
- Includes Fira Code fonts for improved coding experience

## Development Workflow

1. Mount your project directory to `/home/codium/workspace`
2. Access the web IDE through your browser
3. Use integrated terminal for command-line operations
4. Leverage pre-installed development tools and extensions

## Notes

- The container runs without a connection token for easier development access
- SSH agent is automatically started and configured
- Container is configured for cloud-native development workflows
- Multimedia codecs and development libraries are pre-installed

## Technical Details

Base Image: `fedora:latest`
Exposed Port: 3000
Working Directory: `/home/codium`
Default User: codium (UID: 1001)
