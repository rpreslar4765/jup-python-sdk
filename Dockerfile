# Multi-stage Dockerfile for Jup Python SDK
# Supports Alpine Linux 3.18, 3.19, 3.20, 3.21, and edge
# Default Alpine version is 3.21 (latest stable)

ARG ALPINE_VERSION=3.21
ARG PYTHON_VERSION=3.11

# ============================================================================
# Stage 1: Builder - Build dependencies and install packages
# ============================================================================
FROM python:${PYTHON_VERSION}-alpine${ALPINE_VERSION} AS builder

# Update package index and install build dependencies
# Required for Python packages with C extensions (solders, solana, etc.)
RUN apk update && \
    apk add --no-cache \
    gcc \
    g++ \
    musl-dev \
    linux-headers \
    libffi-dev \
    openssl-dev \
    cargo \
    rust \
    make \
    cmake \
    git \
    && rm -rf /var/cache/apk/*

# Set up Python environment
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Install Poetry
RUN pip install --upgrade pip && \
    pip install poetry==1.8.3

WORKDIR /app

# Copy only dependency files first (for better layer caching)
COPY pyproject.toml poetry.lock* ./

# Configure Poetry to not create virtual environment (we're already in a container)
RUN poetry config virtualenvs.create false

# Install dependencies
RUN poetry install --only main --no-root --no-interaction --no-ansi

# Copy the rest of the application
COPY . .

# Install the package itself
RUN poetry install --only-root --no-interaction --no-ansi

# ============================================================================
# Stage 2: Runtime - Minimal runtime image
# ============================================================================
FROM python:${PYTHON_VERSION}-alpine${ALPINE_VERSION} AS runtime

# Install only runtime dependencies
RUN apk update && \
    apk add --no-cache \
    libgcc \
    libstdc++ \
    libffi \
    openssl \
    && rm -rf /var/cache/apk/*

# Create non-root user for security
RUN addgroup -g 1000 jupuser && \
    adduser -D -u 1000 -G jupuser jupuser

WORKDIR /app

# Copy Python packages from builder
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

# Copy application code
COPY --from=builder --chown=jupuser:jupuser /app /app

# Switch to non-root user
USER jupuser

# Set Python environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PATH="/home/jupuser/.local/bin:$PATH"

# Health check (optional - can be customized based on needs)
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import jup_python_sdk; print('OK')" || exit 1

# Default command - run Python shell
CMD ["python"]

# ============================================================================
# Stage 3: Development - Includes development dependencies and tools
# ============================================================================
FROM builder AS development

# Install development dependencies
RUN poetry install --with dev --no-interaction --no-ansi

# Install additional development tools
RUN apk update && \
    apk add --no-cache \
    bash \
    vim \
    curl \
    jq \
    && rm -rf /var/cache/apk/*

WORKDIR /app

# Keep development environment running
CMD ["sh"]

# ============================================================================
# Stage 4: Testing - Optimized for running tests
# ============================================================================
FROM development AS testing

# Copy test files
COPY tests/ ./tests/
COPY examples/ ./examples/

# Run tests by default
CMD ["poetry", "run", "pytest", "--cov=jup_python_sdk", "-v"]

# ============================================================================
# Build instructions:
# ============================================================================
# Build for Alpine 3.18:
#   docker build --build-arg ALPINE_VERSION=3.18 -t jup-python-sdk:alpine3.18 .
#
# Build for Alpine 3.19:
#   docker build --build-arg ALPINE_VERSION=3.19 -t jup-python-sdk:alpine3.19 .
#
# Build for Alpine 3.20:
#   docker build --build-arg ALPINE_VERSION=3.20 -t jup-python-sdk:alpine3.20 .
#
# Build for Alpine 3.21:
#   docker build --build-arg ALPINE_VERSION=3.21 -t jup-python-sdk:alpine3.21 .
#
# Build for Alpine edge (latest development):
#   docker build --build-arg ALPINE_VERSION=edge -t jup-python-sdk:alpine-edge .
#
# Build development image:
#   docker build --target development -t jup-python-sdk:dev .
#
# Build testing image:
#   docker build --target testing -t jup-python-sdk:test .
#
# Run container:
#   docker run -it --env-file .env jup-python-sdk:alpine3.21
# ============================================================================
