## Reliable and Auditable Messaging Platform for Regulated Industries

This is a robust, auditable messaging platform designed for industries with stringent regulatory and compliance requirements. It uses a containerized architecture to ensure every message transaction is reliable, traceable, and secure.

The platform is built using docker-compose and consists of three main services:

- **Kafka**: The core messaging queue. It handles high-throughput message ingestion and distribution, serving as a central hub for all events.

- **PostgreSQL**: The permanent data store for message auditing. Every transaction is logged here, providing an unchangeable record of events for compliance.

- **Redis**: Used as a fast and lightweight Dead Letter Queue (DLQ). Failed messages that cannot be processed by the application are temporarily stored in Redis for later inspection or reprocessing, preventing data loss.

These services are wrraped around by a Python-based consumer application. User can enter any number of successive messages which are sent to a Kafka queue. It then consumes messages from Kafka, processes them based on business logic, and logs the outcomes to PostgreSQL if successful. Failed messages are sent to Redis for future inspection or resend without interrupting Kafka stream.

### Setup

### 1. Prerequisites

To run all services correctly, Docker and Docker Compose need to be installed. For required libraries:
```python
pip install -r requirements.txt
```

### 2. Start Services

From the project root, run the following command to build the application image and start all services.

```bash
docker-compose up --build
docker ps -a
```

### 3. Sending Messages

From the project root, run
```python
python app/producer.py
```
and enter messages to be sent. Unique user IDs will be generated for each message.

### 4. View contents of PostgreSQL

In a new terminal window, run
```bash 
docker-compose exec postgres psql -U admin -d audit_db
```
In the psql terminal, run 
```sql
SELECT * FROM message_audit;
```
Output includes all messages with unique ID and status which may be `MESSAGE_RECEIVED` and `MESSAGE_PROCESSED` for successful messages, or 
`MESSAGE_RECEIVED`, `MESSAGE_FAILED` and `MESSAGE_DLQ` indication they have been sent to Redis DLQ.

### 5. View contents of Redis DLQ

In a new terminal, run
```bash
docker-compose exec redis redis-cli
```
Run Redis commands to inspect the data. This application pushes failed messages to a list named dlq:events_topic.

- To check how many messages are in the DLQ, run the LLEN command:
```bash
LLEN dlq:events_topic
```

- To view the contents of the entire DLQ list without removing the messages, use LRANGE with a range from 0 to -1:
```bash
LRANGE dlq:events_topic 0 -1
```

- To view a single message and remove it from the queue, use LPOP:
```bash
LPOP dlq:events_topic
```






