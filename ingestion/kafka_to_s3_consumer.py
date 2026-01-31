import json
from datetime import datetime
from kafka import KafkaConsumer, TopicPartition
from checkpoint_manager import CheckpointManager
from file_writer import BronzeFileWriter

TOPICS = {
    "asset_snapshots_raw": "asset_snapshots",
    "maintenance_snapshots_raw": "maintenance_snapshots",
    "reference_data_raw": "reference_data"
}

consumer = KafkaConsumer(
    bootstrap_servers="localhost:9092",
    enable_auto_commit=False,
    value_deserializer=lambda v: json.loads(v.decode())
)

cp = CheckpointManager()
checkpoints = cp.load()

for topic, entity in TOPICS.items():
    partitions = consumer.partitions_for_topic(topic)
    tps = [TopicPartition(topic, p) for p in partitions]
    consumer.assign(tps)

    for tp in tps:
        offset = checkpoints.get(topic, {}).get(str(tp.partition), -1)
        consumer.seek(tp, offset + 1)

    writer = BronzeFileWriter(entity)
    max_offsets = {}

    while True:
        records = consumer.poll(2000)
        if not records:
            break

        for tp, msgs in records.items():
            for msg in msgs:
                writer.add({
                    "payload": msg.value,
                    "kafka_topic": msg.topic,
                    "kafka_partition": msg.partition,
                    "kafka_offset": msg.offset,
                    "ingestion_timestamp": datetime.utcnow().isoformat() + "Z"
                })
                max_offsets[(msg.topic, msg.partition)] = msg.offset

    writer.flush()

    for (t,p),off in max_offsets.items():
        checkpoints.setdefault(t,{})[str(p)] = off

cp.persist(checkpoints)
consumer.close()
