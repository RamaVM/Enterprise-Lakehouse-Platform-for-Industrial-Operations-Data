import json, requests
from kafka import KafkaProducer

producer = KafkaProducer(
    bootstrap_servers="localhost:9092",
    value_serializer=lambda v: json.dumps(v).encode(),
    key_serializer=lambda k: k.encode()
)

records = requests.get("http://localhost:8001/maintenance").json()
for r in records:
    producer.send("maintenance_snapshots_raw", key=r["maintenance_id"], value=r)

producer.flush()
