# Default sandbox image of the mogenius Agent Sandbox blueprint.
#
# VS Code in the browser (code-server) plus the tooling agents expect from a
# Daytona-style default sandbox: Python 3 with pip/venv and uv, Node.js (from
# the base image), git, curl, build tools. Runs as the unprivileged user
# `coder` (uid 1000); the sandbox volume is mounted at /home/coder/project.
#
# code-server listens on 8080 without its own auth: sandboxes are only
# reachable through the mogenius tunnel (which authenticates) or the SSH
# gateway, and the chart's NetworkPolicy blocks everything else.
ARG CODE_SERVER_VERSION=4.138.0
FROM codercom/code-server:${CODE_SERVER_VERSION}

USER root
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      python3 python3-pip python3-venv python3-dev \
      build-essential pkg-config \
      jq ripgrep unzip rsync less openssh-server ca-certificates \
 && rm -rf /var/lib/apt/lists/* \
 && ln -sf /usr/bin/python3 /usr/local/bin/python \
 && mkdir -p /home/coder/project /home/coder/.local/bin \
 && chown -R coder:coder /home/coder

# uv: fast Python package manager, what most agent frameworks call today.
RUN curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR=/usr/local/bin sh

USER coder
WORKDIR /home/coder/project
ENV PATH="/home/coder/.local/bin:${PATH}" \
    PIP_BREAK_SYSTEM_PACKAGES=1 \
    UV_LINK_MODE=copy

# Pre-create the settings dir so the volume mount does not hide it.
RUN mkdir -p /home/coder/.local/share/code-server/User \
 && printf '{ "workbench.startupEditor": "none", "telemetry.telemetryLevel": "off" }\n' \
      > /home/coder/.local/share/code-server/User/settings.json

EXPOSE 8080
# /healthz is code-server's health endpoint; the chart's probes use it.
ENTRYPOINT ["/usr/bin/entrypoint.sh", "--bind-addr", "0.0.0.0:8080", "--auth", "none", "/home/coder/project"]
