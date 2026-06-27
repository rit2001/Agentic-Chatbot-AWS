FROM python:3.11-slim

# Prevent Python cache files and enable immediate container logs
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /app

# build-essential supports packages that require compilation
# libgomp1 is required by faiss-cpu
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libgomp1 \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first to leverage Docker build caching
COPY requirements.txt .

# Install Python dependencies
RUN python -m pip install --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Pre-download the HuggingFace embedding model weights into the image layer
# This prevents unauthenticated rate limits and slow startups on AWS EC2
RUN python -c "from langchain_huggingface import HuggingFaceEmbeddings; HuggingFaceEmbeddings(model_name='all-MiniLM-L6-v2')"

# Copy the complete project code into the container
COPY . .

EXPOSE 8501

# Run the Streamlit application with production flags
CMD ["streamlit", "run", "app.py", \
     "--server.port=8501", \
     "--server.address=0.0.0.0", \
     "--server.headless=true", \
     "--browser.gatherUsageStats=false"]