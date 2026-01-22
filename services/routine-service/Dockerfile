# Official Python base image (lightweight)
FROM python:3.13.11-slim

# Prevent Python from generating .pyc files and force real-time console output
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Working directory inside the container
WORKDIR /app

# Install system dependencies (optional but recommended for postgres/other drivers)
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy dependencies and install them
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy project source code
COPY . .

# Expose standard port (internal to container)
EXPOSE 8005

# Make start script executable
RUN chmod +x start.sh

# Default command on startup
CMD ["./start.sh"]