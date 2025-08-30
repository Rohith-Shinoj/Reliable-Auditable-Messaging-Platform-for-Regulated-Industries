# FROM python:3.9-slim

# WORKDIR /app

# COPY app/requirements.txt .
# RUN pip install --no-cache-dir -r requirements.txt

# COPY app/. .

# CMD ["python", "main.py"]

FROM python:3.9-slim

WORKDIR /app

# Install Java and curl
RUN apt-get update && apt-get install -y openjdk-17-jre-headless curl

# Download and extract Kafka binaries
ENV KAFKA_VERSION=3.7.0
ENV SCALA_VERSION=2.13
RUN curl -sL "https://archive.apache.org/dist/kafka/${KAFKA_VERSION}/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz" | tar -xzf - -C /opt/ \
    && ln -s /opt/kafka_${SCALA_VERSION}-${KAFKA_VERSION} /opt/kafka

# Add Kafka bin directory to the PATH
ENV PATH="/opt/kafka/bin:${PATH}"

COPY app/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app/. .

CMD ["python", "main.py"]