import json
import uuid
import time
import random
from kafka import KafkaProducer

producer = KafkaProducer(
    bootstrap_servers=['kafka:9092'],
    value_serializer=lambda v: json.dumps(v).encode('utf-8'),
    api_version=(2, 0, 0)
)

def produce_message(topic, message_id, payload):
    message = {
        'id': message_id,
        'timestamp': int(time.time()),
        'payload': payload
    }
    producer.send(topic, message)
    print(f"Sent message ID: {message_id} to topic: {topic}")

if __name__ == '__main__':
    topic_name = 'events_topic'
    
    while True:
        user_message = input("Enter a message to send (or 'exit' to quit): ")
        if user_message.lower() == 'exit':
            break

        message_id = str(uuid.uuid4())
        
        payload = {'data': user_message}
        
        # Simulate a 25% chance of failure
        if random.random() < 0.25:
            payload['error'] = True
            print("Message marked as failed (simulated random error).")
        
        produce_message(topic_name, message_id, payload)
        
    producer.flush()
    producer.close()
    
    print("Producer finished. All messages sent.")