from fastapi import FastAPI
from data_generator import generate_maintenance

app = FastAPI()

@app.get("/maintenance")
def get_maintenance():
    return [generate_maintenance() for _ in range(200)]
