import json
import uuid
import time
import random
from kafka import KafkaProducer

producer = KafkaProducer(
    bootstrap_servers=['kafka:9092'],
    value_serializer=lambda v: json.dumps(v).encode('utf-8'),
    api_version=(2, 0, 0),
    acks='all',         
    linger_ms=20,        
    compression_type='gzip' 
)

def produce_message(topic, message_id, payload):
    message = {
        'id': message_id,
        'timestamp': int(time.time()),
        'payload': payload
    }
    producer.send(topic, message)
    return message

if __name__ == '__main__':
    message_count = 25000
    topic_name = 'events_topic'

    print(f"Starting Kafka producer, target: {message_count} msgs/sec")

    start_time = time.perf_counter()
    total_sent = 0
    failed = 0

    batch_start = time.perf_counter()
    for i in range(message_count):
        user_message = f"message-{total_sent + i}"
        message_id = str(uuid.uuid4())
        payload = {'data': user_message}

        if random.random() < 0.01:
            payload['error'] = True
            print(f"[DEBUG] Message {message_id} marked as failed.")
            failed += 1

        produce_message(topic_name, message_id, payload)

    producer.flush() 
    batch_end = time.perf_counter()

    batch_duration = batch_end - batch_start
    total_sent += message_count

    print(
        f"[METRIC] Sent {message_count} messages in {batch_duration:.3f}s "
        f"({message_count / batch_duration:.0f} msg/s). "
        f"Total sent: {total_sent} "
        f"Messages failed: {failed} "
    )

    sleep_time = 1.0 - batch_duration
    if sleep_time > 0:
        time.sleep(sleep_time)

    producer.close()
