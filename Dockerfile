FROM mcr.microsoft.com/dotnet/aspnet:10.0-preview AS base
WORKDIR /app
EXPOSE 8080
ENV ASPNETCORE_URLS=http://+:8080

FROM mcr.microsoft.com/dotnet/sdk:10.0-preview AS build
WORKDIR /src
COPY Presso.API/Presso.API.csproj Presso.API/
RUN dotnet restore Presso.API/Presso.API.csproj
COPY Presso.API/ Presso.API/
RUN dotnet publish Presso.API/Presso.API.csproj -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "Presso.API.dll"]
