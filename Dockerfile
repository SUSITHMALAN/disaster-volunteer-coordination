# =========================
# Build ASP.NET Core
# =========================

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build

WORKDIR /src

COPY backend/ ./backend/

RUN dotnet restore backend/src/DVC.Api/DVC.Api.csproj

RUN dotnet publish backend/src/DVC.Api/DVC.Api.csproj \
    -c Release \
    -o /app/publish \
    --no-restore


# =========================
# Runtime
# =========================

FROM mcr.microsoft.com/dotnet/aspnet:8.0

WORKDIR /app

# Install Python
RUN apt-get update && \
    apt-get install -y python3 python3-pip python3-venv && \
    rm -rf /var/lib/apt/lists/*

# Copy ASP.NET application
COPY --from=build /app/publish ./backend/

# Copy Agentic AI
COPY agentic-ai/ ./agentic-ai/

# Install Python dependencies
RUN python3 -m venv /app/venv

RUN /app/venv/bin/pip install --no-cache-dir \
    -r /app/agentic-ai/requirements.txt

# Make Python virtual environment available
ENV PATH="/app/venv/bin:$PATH"

# Startup script
COPY start.sh /app/start.sh

RUN chmod +x /app/start.sh

CMD ["/app/start.sh"]