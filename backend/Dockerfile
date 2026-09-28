FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY . .
RUN dotnet restore src/DVC.Api/DVC.Api.csproj
RUN dotnet publish src/DVC.Api/DVC.Api.csproj -c Release -o /app/publish --no-restore

FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /app
COPY --from=build /app/publish .
CMD ASPNETCORE_URLS=http://+:${PORT:-10000} dotnet DVC.Api.dll
