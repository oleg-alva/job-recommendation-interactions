FROM python:3.12-slim

WORKDIR /app

# Install dependencies first
# This layer will be reused unless changes are made to requirements
COPY requirements.txt .
RUN pip install -r requirements.txt

# Copy application code 
ADD dbt_pipeline dbt_pipeline 
ADD terraform terraform

# Include necessary files for dbt and GCP - TODO: Change this to your project name
COPY profiles.yml .
# COPY google-service-account-<dbt-pipeline>-runtime.json . 

# Copy run script and make executable
COPY run.sh .
RUN chmod +x ./run.sh

EXPOSE 8080

# Point to script that runs the transformations
ENTRYPOINT ["./run.sh"]
