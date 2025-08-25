# Start with .NET SDK As Base Image fo stage #1
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build

# Change directory to /src
WORKDIR /src 

# Copy Backend files to The Working Directory
COPY . .

# Restore dependencies
RUN dotnet restore

WORKDIR /src/GraduationProjectWebApplication

# Generate dll files 
RUN dotnet publish -c Release -o /app/publish

# stage #2
FROM  mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime

# Change Directory 
WORKDIR /app

# Copy dll files Created From Sage #1
COPY --from=build /app/publish .

# Make Container listen on port 5001
EXPOSE 5001

# Run API
ENTRYPOINT ["dotnet", "GraduationProjectWebApplication.dll"]


