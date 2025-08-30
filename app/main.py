import json
import redis
from kafka import KafkaConsumer
from message_processor import process_message
from db_manager import AuditLogger

redis_client = redis.Redis(host='redis', port=6379)
audit_logger = AuditLogger(dbname='audit_db', user='admin', password='password', host='postgres')

consumer = KafkaConsumer(
    'events_topic',
    bootstrap_servers=['kafka:9092'],
    value_deserializer=lambda x: json.loads(x.decode('utf-8')),
    api_version=(2, 0, 0)
)

def run_consumer():
    for message in consumer:
        msg_id = message.value.get('id')
        print(f"Received message with ID: {msg_id}")

        log_details = message.value.copy()
        log_details['kafka_metadata'] = {
            'partition': message.partition,
            'offset': message.offset
        }

        # Log 
        audit_logger.log_event(msg_id, 'MESSAGE_RECEIVED', details=log_details)

        if process_message(message.value):
            audit_logger.log_event(msg_id, 'MESSAGE_PROCESSED')
        else:
            audit_logger.log_event(msg_id, 'MESSAGE_FAILED')
            redis_client.lpush('dlq:events_topic', json.dumps(message.value))
            audit_logger.log_event(msg_id, 'MESSAGE_DLQ')

if __name__ == '__main__':
    try:
        run_consumer()
    finally:
        audit_logger.close()