#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

echo "Checking prerequisites..."
if ! command -v docker &> /dev/null || ! command -v docker-compose &> /dev/null; then
    echo "Docker and/or Docker Compose are not installed. Please install them to continue."
    exit 1
fi

if [ ! -f app/requirements.txt ]; then
    echo "Warning: requirements.txt not found. Skipping Python library installation."
else
    pip install -r app/requirements.txt
fi

echo "Building and starting services..."
docker-compose up --build -d
echo "Services are running."

while true; do
    echo " "
    echo "--- Main Menu ---"
    echo "1. Send a new message"
    echo "2. View PostgreSQL logs"
    echo "3. View Redis DLQ logs"
    echo "4. View cleaned messages"
    echo "5. Restart services with fresh logs"
    echo "6. Exit script"
    echo " "
    read -p "Enter your choice (1-6):" choice

    case $choice in

        1)
            echo "---"
            echo "Starting message producer. Press Ctrl+C to return to the menu."
            docker-compose exec app python producer.py || true
            echo " "
            echo "Messages sent. Returning to main menu."
            ;;
        2)
            echo "---"
            echo "To open psql terminal, run:"
            echo "docker-compose exec postgres psql -U admin -d audit_db"
            echo "Viewing contents of PostgresSQL logs:"
            docker-compose exec postgres psql -U admin -d audit_db -c "SELECT * FROM message_audit;"
            # echo "Cleaned PostgreSQL logs for better readability:"
            # docker-compose exec postgres psql -U admin -d audit_db -c "SELECT
            #                                                             message_id,
            #                                                             details->'payload'->>'data' AS payload_text,
            #                                                             timestamp,
            #                                                             CASE
            #                                                                 WHEN EXISTS (SELECT 1 FROM message_audit ma2 WHERE ma2.message_id = ma1.message_id AND ma2.event_type = 'MESSAGE_DLQ')
            #                                                                 THEN 'Failed'
            #                                                                 ELSE 'Successful'
            #                                                             END AS status
            #                                                             FROM
            #                                                                 message_audit ma1
            #                                                             WHERE
            #                                                                 event_type = 'MESSAGE_RECEIVED'
            #                                                             ORDER BY
            #                                                                 timestamp;"
            ;;
        3)
            echo "---"
            echo "Viewing contents of Redis DLQ..."
            echo "Number of messages in DLQ:"
            docker-compose exec redis redis-cli LLEN dlq:events_topic
            echo "Contents of DLQ:"
            docker-compose exec redis redis-cli LRANGE dlq:events_topic 0 -1
            ;;
        4)
            echo "---"
            echo "Viewing messages with status from PostgreSQL logs:"
            docker-compose exec postgres psql -U admin -d audit_db -c "SELECT
                                                                        message_id,
                                                                        details->'payload'->>'data' AS payload_text,
                                                                        timestamp,
                                                                        CASE
                                                                            WHEN EXISTS (SELECT 1 FROM message_audit ma2 WHERE ma2.message_id = ma1.message_id AND ma2.event_type = 'MESSAGE_DLQ')
                                                                            THEN 'Failed'
                                                                            ELSE 'Successful'
                                                                        END AS status
                                                                        FROM
                                                                            message_audit ma1
                                                                        WHERE
                                                                            event_type = 'MESSAGE_RECEIVED'
                                                                        ORDER BY
                                                                            timestamp;"
            echo " "
            echo "Viewing contents of Redis DLQ"
            # docker-compose exec redis redis-cli LRANGE dlq:events_topic 0 -1 | jq '.[] | {id, timestamp, payload: .payload.data}'
            docker-compose exec redis redis-cli --raw LRANGE dlq:events_topic 0 -1 | sed 's/\\//g' | tr '\n' ',' | sed 's/,$/\n/' | sed 's/^/[/; s/$/]/' | jq '.[] | {id, timestamp, payload: .payload.data}'            ;;

        5)
            echo "---"
            echo "Restarting services with fresh logs..."
            docker-compose down
            docker-compose down --volumes
            docker-compose up --build -d
            echo "Services restarted."
            ;;

        6)
            echo "---"
            echo "Exiting script. Stopping services..."
            docker-compose down
            echo "Services stopped. Goodbye!"
            exit 0
            ;;
        *)
            echo "---"
            echo "Invalid choice. Please enter a number from 1 to 4."
            ;;
    esac

    echo " "
    echo "Press [Enter] to continue..."
    read -n 1 -s -r -p ""
done