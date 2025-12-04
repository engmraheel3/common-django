FROM python:3.11-slim

# Install netcat for health checks
RUN apt-get update && apt-get install -y netcat-traditional && rm -rf /var/lib/apt/lists/*

WORKDIR /mysite
    
COPY ./requirements.txt /mysite/
RUN pip install --no-cache-dir -r requirements.txt

COPY . /mysite/
# Make entrypoint executable
RUN chmod +x /mysite/entrypoint.sh

ENV PYTHONUNBUFFERED=1

ENTRYPOINT ["/mysite/entrypoint.sh"]