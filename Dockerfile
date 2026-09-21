# syntax=docker/dockerfile:1

FROM quay.io/hummingbird/python:3.13-builder AS builder
USER 0

# uv: reproducible installs straight from uv.lock (static binary, version-pinned).
COPY --from=ghcr.io/astral-sh/uv:0.11.16 /uv /usr/local/bin/uv

ENV UV_PYTHON=3.13 \
    UV_PYTHON_DOWNLOADS=0 \
    UV_PROJECT_ENVIRONMENT=/opt/venv \
    UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy

WORKDIR /build

COPY pyproject.toml uv.lock README.md ./
RUN uv sync --frozen --no-dev --no-install-project

RUN mkdir -p /scratch

# Runtime — distroless, non-root (UID 65532). Ships only the venv + app code:
# no shell, no package manager, no build tools, no frontend, no tests.
FROM quay.io/hummingbird/python:3.13
USER 0

COPY --from=builder /opt/venv /opt/venv
COPY --from=builder --chown=65532:65532 /scratch /scratch

WORKDIR /app
COPY gunicorn_config.py ./
COPY src ./src

ENV PATH="/opt/venv/bin:$PATH" \
    VIRTUAL_ENV=/opt/venv \
    PYTHONPATH=/app \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    HOME=/scratch \
    TMPDIR=/scratch \
    LOG_DIR=/scratch/logs

USER 65532:65532
EXPOSE 8080
CMD ["/opt/venv/bin/gunicorn", "-c", "gunicorn_config.py", "src.main:app"]
