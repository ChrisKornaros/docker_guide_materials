# Use the official Python slim image as our base
# The slim variant balances size (~150MB) with compatibility
FROM python:3.11-slim

# Set environment variables for Python behavior inside the container
# PYTHONDONTWRITEBYTECODE: Prevents Python from writing .pyc bytecode files to disk,
#   keeping the container filesystem cleaner
# PYTHONUNBUFFERED: Forces stdout and stderr to be unbuffered, ensuring log output
#   appears immediately in `docker logs` rather than being held in a buffer
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Set the working directory for all subsequent instructions
WORKDIR /app

# Install system-level build dependencies needed for compiling Python packages
# with C extensions (numpy, pandas, etc.), then clean up apt caches to reduce
# the layer size. Combining install and cleanup in one RUN avoids persisting
# the apt cache in a separate layer.
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        gcc \
        libffi-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy the dependency manifest first, separately from application code.
# This ensures Docker can cache the expensive pip install layer and only
# re-run it when requirements.txt actually changes.
COPY requirements.txt .

# Install Python dependencies without caching downloaded archives.
# The --no-cache-dir flag prevents pip from storing .whl and .tar.gz files
# inside the image, which would bloat the layer with no runtime benefit.
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application code into the container.
# This layer changes most frequently, so placing it last maximizes
# cache reuse for all preceding layers.
COPY . .

# Document the port our Python application will listen on.
# This is informational only — actual publishing happens with -p at runtime.
EXPOSE 8000

# Default command: start an interactive Python shell.
# This can be overridden at runtime with docker run ... python my_script.py
CMD ["python"]