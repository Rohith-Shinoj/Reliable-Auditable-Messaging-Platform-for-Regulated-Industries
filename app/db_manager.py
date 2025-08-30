import psycopg2
from datetime import datetime
import json

class AuditLogger:
    def __init__(self, dbname, user, password, host):
        self.conn = psycopg2.connect(dbname=dbname, user=user, password=password, host=host)
        self.cursor = self.conn.cursor()
        self.create_table()

    def create_table(self):
        self.cursor.execute("""
            CREATE TABLE IF NOT EXISTS message_audit (
                id SERIAL PRIMARY KEY,
                message_id VARCHAR(255) NOT NULL,
                event_type VARCHAR(50) NOT NULL,
                timestamp TIMESTAMP NOT NULL,
                details JSONB
            );
        """)
        self.conn.commit()

    def log_event(self, message_id, event_type, details=None):
        timestamp = datetime.now()
        if details:
            details_json = json.dumps(details)
        else:
            details_json = None
        
        self.cursor.execute("""
            INSERT INTO message_audit (message_id, event_type, timestamp, details)
            VALUES (%s, %s, %s, %s);
        """, (message_id, event_type, timestamp, details_json))
        self.conn.commit()

    def close(self):
        self.cursor.close()
        self.conn.close()