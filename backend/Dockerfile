# Stage 1: Build the application
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copy solution and project files
COPY backend/GraduationProjectDotNet.sln ./
COPY backend/GraduationProjectWebApplication/GraduationProjectWebApplication.csproj ./GraduationProjectWebApplication/
COPY backend/StaticDetails/GraduationProject.StaticDetails.csproj ./StaticDetails/

# Restore dependencies
RUN dotnet restore GraduationProjectWebApplication/GraduationProjectWebApplication.csproj

# Copy the rest of the source code
COPY backend/ ./

# Build and publish the application
WORKDIR /src/GraduationProjectWebApplication
RUN dotnet publish -c Release -o /app/publish

# Stage 2: Create the final runtime image
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime
WORKDIR /app

# Copy published files from build stage
COPY --from=build /app/publish .

# Expose port
EXPOSE 5001

# CORRECTED GARBAGE COLLECTION SETTINGS FOR WEB API WITH ML WORKLOADS
# Enable Server GC (multi-threaded, better for web servers)
ENV DOTNET_gcServer=1

# Use 2 GC heaps (matches your CPU cores)
ENV DOTNET_GCHeapCount=2

# Disable memory conservation mode (allows GC to be more aggressive)
ENV DOTNET_GCConserveMemory=0

# Set heap hard limit to 1.5GB (leaves room for native memory used by ONNX)
ENV DOTNET_GCHeapHardLimit=0x60000000

# Enable concurrent GC for better responsiveness
ENV DOTNET_gcConcurrent=1

# Set entry point
ENTRYPOINT ["dotnet", "GraduationProjectWebApplication.dll"]
