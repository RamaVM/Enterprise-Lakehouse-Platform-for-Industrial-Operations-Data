import json, uuid, boto3
from datetime import datetime

BUCKET = "enterprise-lakehouse-data"

class BronzeFileWriter:
    def __init__(self, entity, max_records=5000):
        self.entity = entity
        self.buffer = []
        self.s3 = boto3.client("s3")
        self.max_records = max_records

    def add(self, record):
        self.buffer.append(record)
        if len(self.buffer) >= self.max_records:
            self.flush()

    def flush(self):
        if not self.buffer:
            return
        date = datetime.utcnow().strftime("%Y-%m-%d")
        key = f"bronze/{self.entity}/ingestion_date={date}/part-{uuid.uuid4().hex}.json"
        body = "\n".join(json.dumps(r) for r in self.buffer)
        self.s3.put_object(Bucket=BUCKET, Key=key, Body=body.encode())
        self.buffer.clear()
