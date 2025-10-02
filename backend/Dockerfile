# Stage 1: Build the application using the .NET 8 SDK
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build

# Set the working directory for the build commands
WORKDIR /src

# Copy the entire project source code into the container
COPY . .

# Restore the project dependencies and NuGet packages
RUN dotnet restore

# Publish the application for release to the /app/publish folder
RUN dotnet publish -c Release -o /app/publish

# Stage 2: Create the final runtime image
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime

# Set the working directory for the application
WORKDIR /app

# Copy only the published files from the build stage
COPY --from=build /app/publish .

# Document that the container listens on port 5001 at runtime
EXPOSE 5001

# Define the command to run the application
ENTRYPOINT ["dotnet", "GraduationProjectWebApplication.dll"]
