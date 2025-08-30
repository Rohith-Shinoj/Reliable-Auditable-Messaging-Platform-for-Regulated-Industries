def process_message(message):
    try:
        if 'error' in message['payload']:
            raise ValueError("Processing failed due to business logic error.")
        print(f"Successfully processed message ID: {message['id']}")
        return True
    except Exception as e:
        print(f"Failed to process message ID: {message['id']}. Reason: {e}")
        return False
