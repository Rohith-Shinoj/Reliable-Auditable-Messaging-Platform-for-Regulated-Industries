FROM python:3.9-slim

WORKDIR /app

# Install Java 
RUN apt-get update && apt-get install -y openjdk-17-jre-headless curl

ENV KAFKA_VERSION=3.7.0
ENV SCALA_VERSION=2.13
RUN curl -sL "https://archive.apache.org/dist/kafka/${KAFKA_VERSION}/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz" | tar -xzf - -C /opt/ \
    && ln -s /opt/kafka_${SCALA_VERSION}-${KAFKA_VERSION} /opt/kafka

ENV PATH="/opt/kafka/bin:${PATH}"

COPY app/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app/. .

CMD ["python", "main.py"]