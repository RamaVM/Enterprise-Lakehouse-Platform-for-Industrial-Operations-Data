import random
from faker import Faker
from datetime import datetime, timedelta

fake = Faker()
CHAOS_LEVEL = 0.3

ASSET_TYPES = ["GENERATOR", "TURBINE", "COMPRESSOR"]
STATUS = ["ACTIVE", "INACTIVE", "MAINTENANCE"]

def maybe_null(v):
    return None if random.random() < CHAOS_LEVEL else v

def corrupt_num(v):
    return -v if random.random() < CHAOS_LEVEL else v

def random_date():
    return (
        datetime.utcnow() + timedelta(days=random.randint(-365, 365))
    ).strftime("%Y-%m-%d")

def generate_asset():
    return {
        "asset_id": f"AST-{random.randint(1000,1100)}",
        "plant_id": maybe_null(f"PLANT-{random.randint(1,10)}"),
        "asset_type": random.choice(ASSET_TYPES),
        "install_date": random_date(),
        "capacity_mw": corrupt_num(random.randint(10,500)),
        "status": random.choice(STATUS),
        "last_updated": datetime.utcnow().strftime("%Y-%m-%d")
    }

def generate_maintenance():
    return {
        "maintenance_id": f"MNT-{random.randint(10000,10200)}",
        "asset_id": f"AST-{random.randint(1000,1100)}",
        "maintenance_type": random.choice(["PREVENTIVE","BREAKDOWN"]),
        "cost": corrupt_num(random.randint(1000,20000)),
        "status": random.choice(["COMPLETED","PENDING"]),
        "actual_date": maybe_null(random_date())
    }

def generate_reference():
    return {
        "asset_type": random.choice(ASSET_TYPES),
        "risk_level": random.choice(["LOW","MEDIUM","HIGH"]),
        "maintenance_cycle_days": maybe_null(random.randint(30,180))
    }
