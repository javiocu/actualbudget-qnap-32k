# Actual Budget for QNAP NAS (ARMv7 - 32KB Page Size)

> ⚠️ **UNOFFICIAL BUILD** - This is a community adaptation of [Actual Budget](https://actualbudget.org) 
> for QNAP NAS compatibility. Not affiliated with or endorsed by the Actual Budget project.
> 
> **Official project:** https://github.com/actualbudget/actual

Custom-built **Actual Budget v26.2.0** image for **QNAP NAS devices** with ARMv7 CPUs and 32KB memory page size (e.g., TS-431P3 with Annapurna Labs AL314 kernel).

## The Problem

Official Actual Budget Docker images crash on certain QNAP NAS models with:

```
ELF load command address/offset not page-aligned
Segmentation fault (core dumped)
```

This happens because the pre-compiled `better-sqlite3` native module uses 4KB memory page alignment, which is incompatible with QNAP devices running kernels with 32KB page size.

## The Solution

This image rebuilds `better-sqlite3` from source with the correct linker flag:

```bash
LDFLAGS="-Wl,-z,max-page-size=32768"
```

## Supported Hardware

✅ **Tested & Verified:**
- QNAP TS-431P3 (Annapurna Labs Alpine AL314 CPU)

⚠️ **Likely Compatible:**
- QNAP TS-431P2
- QNAP TS-231P3
- Other ARMv7 QNAP NAS models with 32KB page kernels

## Quick Start

### Docker Compose (Recommended)

Create `docker-compose.yml`:

```yaml
version: '3.8'

services:
  actual-budget:
    image: javiocu/actualbudget-qnap-32k:latest
    container_name: actual-budget
    restart: unless-stopped
    ports:
      - "5006:5006"
    volumes:
      - ./actual-data:/data
    environment:
      - TZ=Europe/Madrid
      - NODE_ENV=production
```

**Deploy:**

```bash
mkdir -p actual-data
docker-compose up -d
```

Access at: **http://your-nas-ip:5006**

### Docker CLI

```bash
docker run -d \\
  --name actual-budget \\
  --restart unless-stopped \\
  -p 5006:5006 \\
  -v $(pwd)/actual-data:/data \\
  -e TZ=Europe/Madrid \\
  javiocu/actualbudget-qnap-32k:latest
```

## HTTPS Setup (Recommended)

For full functionality (SharedArrayBuffer support), use QNAP's built-in reverse proxy:

1. **QNAP Control Panel → Security → Reverse Proxy**
2. Create new rule:
   - **Source:** HTTPS, Port 5007
   - **Destination:** HTTP, localhost, Port 5006
3. In **Advanced Settings**, add custom headers:
   ```
   Cross-Origin-Opener-Policy: same-origin
   Cross-Origin-Embedder-Policy: require-corp
   ```

Access at: **https://your-nas-ip:5007**

**Alternative:** Click "Advanced Options → Enable Fallback Mode" in Actual Budget if you don't need HTTPS.

## What's New in v26.2.0

- 📊 **Multiple dashboard pages** - Organize reports in tabs
- 📈 **Budget analysis report** - Track category balances over time (experimental)
- 🎨 **Custom themes** - Install color themes (experimental)
- 🔍 **RegEx search/replace** - In transaction notes
- 📱 **Improved mobile performance** - Faster transaction lists
- ⚙️ **Server preferences** - Better sync across devices

[Full release notes](https://actualbudget.org/blog/release-26.2.0/)

## Backup & Restore

### Backup

```bash
tar -czf actual-backup-$(date +%Y%m%d).tar.gz actual-data/
```

**Important:** Budget files are stored in the `/data` volume. Back them up regularly!

### Restore

```bash
docker-compose down
tar -xzf actual-backup-20260206.tar.gz
docker-compose up -d
```

## Building from Source

### Prerequisites

- Docker with buildx support
- QEMU for ARM emulation

```bash
# Enable ARM emulation
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes

# Build image
docker buildx build \\
  --platform linux/arm/v7 \\
  -t actualbudget-qnap-32k:latest \\
  --load .
```

## Troubleshooting

### "SharedArrayBuffer is not available" Error

**Cause:** Browser security restrictions require HTTPS + special headers.

**Solutions:**
1. Use QNAP reverse proxy with custom headers (see HTTPS Setup)
2. Or enable "Fallback Mode" in Actual Budget's error screen

### Container Won't Start

```bash
# Check logs
docker logs actual-budget

# Verify folder permissions
sudo chown -R 1000:1000 actual-data/
```

### Slow Performance

- Check memory limits in docker-compose
- Close unused browser tabs
- Clear browser cache

## Available Tags

| Tag | Description |
|-----|-------------|
| `latest` | Most recent stable build |
| `26.2.0` | Specific version (recommended for production) |
| `26.2.0-node18` | Explicit Node.js version tag |

## Technical Details

- **Base Image:** Debian Bullseye + Node.js 18
- **Actual Budget Version:** v26.2.0 (February 2026)
- **Architecture:** linux/arm/v7 (ARMv7l 32-bit)
- **Key Fix:** better-sqlite3 rebuilt with `-Wl,-z,max-page-size=32768`
- **Runtime:** Node.js 18.x (compatible with Actual v26.2.0)

### Differences from Official Image

| Aspect | Official Image | This Image |
|--------|----------------|------------|
| **Base** | Alpine Linux | Debian Bullseye |
| **better-sqlite3** | Pre-compiled (4KB pages) | Rebuilt for 32KB pages |
| **QNAP TS-431P3** | ❌ Crashes | ✅ Works |
| **Target** | General x86/ARM64 | ARMv7 + 32KB pages |

## Known Limitations

⚠️ **Node.js Version:** This image uses Node.js 18 runtime while Actual Budget v26+ officially requires Node.js 22. However, it works because only `better-sqlite3` is recompiled; the application code is pre-bundled from the official image. Future versions may require a Node.js 20+ rebuild.

⚠️ **Architecture:** Only supports ARMv7 (32-bit). Not compatible with x86_64 or ARM64.

## Updating

When a new Actual Budget version is released:

```bash
cd actualbudget-qnap-32k

# Backup first!
tar -czf actual-backup-before-upgrade.tar.gz actual-data/

# Update image tag in docker-compose.yml
# Example: javiocu/actualbudget-qnap-32k:26.3.0

docker-compose pull
docker-compose up -d
```

All budget data is preserved in the `/data` volume.

## Contributing

Contributions are welcome! If you have:
- Bug fixes
- Improvements to the Dockerfile
- Documentation updates
- Tested compatibility with other QNAP models

Please open an issue or pull request.

## Related Projects

- [Official Actual Budget](https://github.com/actualbudget/actual) - The upstream project
- [actualbudget/actual-server](https://hub.docker.com/r/actualbudget/actual-server) - Official Docker images
- [LinuxServer.io Actual](https://github.com/linuxserver/docker-actual) - Alternative community build

## License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

Based on [Actual Budget](https://github.com/actualbudget/actual) which is also MIT licensed.

## Credits

- **Actual Budget Team** - For creating an amazing open-source budgeting tool
- **QNAP Community** - For documenting the 32KB page size issue
- **better-sqlite3** - For the rebuildable native module

## Disclaimer

This is an **unofficial build** created for QNAP compatibility. It is not affiliated with, endorsed by, or supported by the Actual Budget project or its maintainers.

For issues specific to this build, please open an issue in this repository.
For general Actual Budget support, visit:
- [Actual Budget Discord](https://discord.gg/pRYNYr4W5A)
- [Official Documentation](https://actualbudget.org/docs/)

---

**Made with ❤️ for QNAP users who want privacy-focused budgeting on their NAS withouth fucking 32k problems**
