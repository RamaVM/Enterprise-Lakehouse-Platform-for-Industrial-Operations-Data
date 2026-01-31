import json, requests
from kafka import KafkaProducer

producer = KafkaProducer(
    bootstrap_servers="localhost:9092",
    value_serializer=lambda v: json.dumps(v).encode(),
    key_serializer=lambda k: k.encode()
)

records = requests.get("http://localhost:8002/reference/asset-types").json()
for r in records:
    producer.send("reference_data_raw", key=r["asset_type"], value=r)

producer.flush()
