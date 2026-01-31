from fastapi import FastAPI
from data_generator import generate_asset

app = FastAPI()

@app.get("/assets")
def get_assets():
    return [generate_asset() for _ in range(100)]
