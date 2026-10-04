#!/bin/sh

echo "Starting Agentic AI service..."

cd /app/agentic-ai

uvicorn api:app --host 127.0.0.1 --port 8000 &

echo "Starting ASP.NET Core backend..."

cd /app/backend

ASPNETCORE_URLS=http://+:${PORT:-10000} dotnet DVC.Api.dll