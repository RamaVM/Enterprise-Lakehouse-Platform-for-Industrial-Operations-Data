import json, boto3
from botocore.exceptions import ClientError

BUCKET = "enterprise-lakehouse-data"
KEY = "metadata/kafka_checkpoints/step3_offsets.json"

class CheckpointManager:
    def __init__(self):
        self.s3 = boto3.client("s3")

    def load(self):
        try:
            obj = self.s3.get_object(Bucket=BUCKET, Key=KEY)
            return json.loads(obj["Body"].read())
        except ClientError:
            return {}

    def persist(self, data):
        self.s3.put_object(
            Bucket=BUCKET,
            Key=KEY,
            Body=json.dumps(data, indent=2).encode()
        )
