FROM python:3.12-slim

WORKDIR /app

# Install dependencies first
# This layer will be reused unless changes are made to requirements
COPY requirements.txt .
RUN pip install -r requirements.txt

# Copy application code 
ADD job_recommendation_interactions job_recommendation_interactions 
ADD terraform terraform

# Include necessary files for dbt and GCP
COPY profiles.yml .
COPY google-service-account-job-rec-interactions-runtime.json . 

# Copy run script and make executable
COPY run.sh .
RUN chmod +x ./run.sh

EXPOSE 8080

# Point to script that runs the transformations
ENTRYPOINT ["./run.sh"]
