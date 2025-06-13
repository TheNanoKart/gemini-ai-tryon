# Use an official Python runtime as a parent image
FROM python:3.9-slim-buster

# Set the working directory in the container
WORKDIR /app

# Install dependencies
# Copy requirements.txt first to leverage Docker cache
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the Flask application code and other necessary files
COPY . .

# Cloud Run expects the application to listen on the port specified by the PORT environment variable.
# We'll default to 8080, which is the standard for Cloud Run.
ENV PORT 8080
EXPOSE 8080

# Run the application using Gunicorn, binding to 0.0.0.0 and the specified port.
# 'app:app' assumes your Flask application instance is named 'app' in 'app.py'.
CMD ["gunicorn", "--bind", "0.0.0.0:8080", "app:app"]
