# Docker Support for Jup Python SDK

This document provides comprehensive information about running the Jup Python SDK in Docker containers with support for multiple Alpine Linux versions.

## Supported Alpine Versions

The Jup Python SDK Docker images support the following Alpine Linux versions:

- **Alpine 3.18** - Stable release
- **Alpine 3.19** - Stable release
- **Alpine 3.20** - Stable release
- **Alpine 3.21** - Latest stable release (default)
- **Alpine edge** - Rolling release (latest development)

## Quick Start

### Using Docker

#### 1. Build the Docker Image

Build using the default Alpine version (3.21):

```bash
docker build -t jup-python-sdk .
```

Build for a specific Alpine version:

```bash
# Alpine 3.18
docker build --build-arg ALPINE_VERSION=3.18 -t jup-python-sdk:alpine3.18 .

# Alpine 3.19
docker build --build-arg ALPINE_VERSION=3.19 -t jup-python-sdk:alpine3.19 .

# Alpine 3.20
docker build --build-arg ALPINE_VERSION=3.20 -t jup-python-sdk:alpine3.20 .

# Alpine 3.21 (default)
docker build --build-arg ALPINE_VERSION=3.21 -t jup-python-sdk:alpine3.21 .

# Alpine edge
docker build --build-arg ALPINE_VERSION=edge -t jup-python-sdk:alpine-edge .
```

#### 2. Run a Container

Create a `.env` file with your private key:

```bash
echo "PRIVATE_KEY=your_base58_private_key_here" > .env
```

Run an interactive Python session:

```bash
docker run -it --env-file .env jup-python-sdk
```

Run an example script:

```bash
docker run --rm --env-file .env jup-python-sdk python examples/balances/main.py
```

### Using Docker Compose

Docker Compose provides an easy way to test all Alpine versions simultaneously.

#### 1. Build All Images

```bash
docker-compose build
```

Build specific service:

```bash
docker-compose build jup-sdk-alpine-3-21
```

#### 2. Run All Alpine Versions

Test SDK loading on all Alpine versions:

```bash
docker-compose up
```

Run specific Alpine version:

```bash
docker-compose up jup-sdk-alpine-3-21
```

#### 3. Development Environment

Start an interactive development shell:

```bash
docker-compose up -d jup-sdk-dev
docker-compose exec jup-sdk-dev sh
```

Inside the development container, you can:

```bash
# Run tests
poetry run pytest

# Run linters
poetry run black jup_python_sdk tests
poetry run flake8 jup_python_sdk tests

# Run type checking
poetry run mypy jup_python_sdk
```

#### 4. Run Tests in Docker

```bash
docker-compose up jup-sdk-test
```

## Multi-Stage Build Targets

The Dockerfile includes multiple build targets for different use cases:

### 1. Runtime (Default)

Minimal production image with only runtime dependencies:

```bash
docker build --target runtime -t jup-python-sdk:runtime .
```

**Features:**
- Minimal size
- Only runtime dependencies
- Non-root user for security
- Health check included

### 2. Development

Full development environment with all dev tools:

```bash
docker build --target development -t jup-python-sdk:dev .
```

**Features:**
- All development dependencies (pytest, black, flake8, mypy, etc.)
- Additional development tools (bash, vim, curl, jq)
- Suitable for development and debugging

### 3. Testing

Optimized for running tests:

```bash
docker build --target testing -t jup-python-sdk:test .
```

**Features:**
- Includes test files
- Includes example files
- Runs tests by default
- Generates coverage reports

## Advanced Usage

### Custom Python Version

Build with a specific Python version:

```bash
docker build \
  --build-arg PYTHON_VERSION=3.12 \
  --build-arg ALPINE_VERSION=3.21 \
  -t jup-python-sdk:py312-alpine3.21 .
```

### Running Examples

Run the order-and-execute example:

```bash
docker run --rm --env-file .env jup-python-sdk \
  python examples/order-and-execute/main.py
```

Run the balances example:

```bash
docker run --rm --env-file .env jup-python-sdk \
  python examples/balances/main.py
```

### Interactive Python Shell

Start an interactive Python shell with the SDK loaded:

```bash
docker run -it --env-file .env jup-python-sdk
```

Then in Python:

```python
from jup_python_sdk.clients.ultra_api_client import UltraApiClient
from jup_python_sdk.models.ultra_api.ultra_order_request_model import UltraOrderRequest

client = UltraApiClient()
# Use the client...
```

### Volume Mounting

Mount your local code for development:

```bash
docker run -it --env-file .env \
  -v $(pwd):/app \
  jup-python-sdk:dev \
  sh
```

### Custom Command

Run a custom Python script:

```bash
docker run --rm --env-file .env \
  -v $(pwd)/my_script.py:/app/my_script.py \
  jup-python-sdk \
  python /app/my_script.py
```

## Environment Variables

The SDK requires the following environment variables:

| Variable | Description | Required | Default |
|----------|-------------|----------|---------|
| `PRIVATE_KEY` | Your Solana private key (base58 or uint8 array) | Yes | None |
| `PRIVATE_KEY` can also be set via custom env var | Use `private_key_env_var` parameter | No | `PRIVATE_KEY` |

### Setting Environment Variables

#### Option 1: Using .env file (Recommended)

```bash
# Create .env file
echo "PRIVATE_KEY=your_base58_private_key_here" > .env

# Run with .env file
docker run --env-file .env jup-python-sdk
```

#### Option 2: Using -e flag

```bash
docker run -e PRIVATE_KEY=your_key_here jup-python-sdk
```

#### Option 3: Using docker-compose.yml

```yaml
services:
  jup-sdk:
    image: jup-python-sdk
    environment:
      - PRIVATE_KEY=${PRIVATE_KEY}
```

## Image Sizes

Approximate image sizes for each Alpine version:

| Alpine Version | Runtime | Development | Testing |
|----------------|---------|-------------|---------|
| Alpine 3.18    | ~150MB  | ~300MB      | ~320MB  |
| Alpine 3.19    | ~150MB  | ~300MB      | ~320MB  |
| Alpine 3.20    | ~150MB  | ~300MB      | ~320MB  |
| Alpine 3.21    | ~150MB  | ~300MB      | ~320MB  |
| Alpine edge    | ~150MB  | ~300MB      | ~320MB  |

*Note: Actual sizes may vary depending on dependencies and caching.*

## Security Features

### Non-Root User

The runtime image runs as a non-root user (`jupuser`) for enhanced security:

```dockerfile
USER jupuser
```

### Minimal Runtime Dependencies

Only essential runtime libraries are included:
- libgcc
- libstdc++
- libffi
- openssl

### Health Check

The runtime image includes a health check:

```bash
docker inspect --format='{{.State.Health.Status}}' <container_id>
```

## Troubleshooting

### Build Failures

If you encounter build failures:

1. **Clear Docker cache:**
   ```bash
   docker builder prune -a
   ```

2. **Build without cache:**
   ```bash
   docker build --no-cache -t jup-python-sdk .
   ```

3. **Check Alpine version support:**
   Ensure the Python version is available for your chosen Alpine version.

### Runtime Issues

1. **Missing private key:**
   ```
   Error: PRIVATE_KEY environment variable not set
   ```
   Solution: Ensure .env file exists or pass via -e flag

2. **Permission denied:**
   The container runs as non-root user. If mounting volumes, ensure proper permissions:
   ```bash
   chmod -R 755 ./examples
   ```

3. **Import errors:**
   If SDK import fails, rebuild the image:
   ```bash
   docker build --no-cache -t jup-python-sdk .
   ```

## CI/CD Integration

GitHub Actions workflow is included to test all Alpine versions automatically. See `.github/workflows/docker-alpine.yml` for the complete CI configuration.

### Running CI Locally

Test the same checks locally using [act](https://github.com/nektos/act):

```bash
act -j docker-build-test
```

## Performance Considerations

### Build Time Optimization

- **Layer caching:** Dependencies are copied before source code to maximize cache hits
- **Multi-stage builds:** Separate builder and runtime stages minimize final image size
- **Parallel builds:** Use Docker Compose to build multiple versions in parallel

### Runtime Performance

- Alpine Linux is lightweight and optimized for containers
- All Alpine versions provide similar runtime performance
- Use Alpine 3.21 (default) for best balance of stability and features

## Best Practices

1. **Use specific Alpine versions in production:**
   ```bash
   docker build --build-arg ALPINE_VERSION=3.21 -t jup-python-sdk:prod .
   ```

2. **Always use .env files for secrets:**
   Never hardcode private keys in Dockerfiles or docker-compose.yml

3. **Use multi-stage builds:**
   Keep production images minimal by using the runtime target

4. **Regular updates:**
   Rebuild images regularly to get security updates:
   ```bash
   docker build --pull --no-cache -t jup-python-sdk .
   ```

5. **Version tagging:**
   Tag images with SDK version and Alpine version:
   ```bash
   docker build -t jup-python-sdk:1.2.0-alpine3.21 .
   ```

## Additional Resources

- [Alpine Linux Documentation](https://docs.alpinelinux.org/)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Jupiter Ultra API Docs](https://dev.jup.ag/docs/ultra-api/)
- [Jup Python SDK Repository](https://github.com/Jupiter-DevRel/jup-python-sdk)

## Support

For issues related to:
- **SDK functionality:** Open an issue in the main repository
- **Docker setup:** Check this documentation first, then open an issue
- **Alpine-specific issues:** Consult Alpine Linux documentation

## License

This Docker configuration is part of the Jup Python SDK and follows the same MIT License.
