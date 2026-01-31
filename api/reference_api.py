from fastapi import FastAPI
from data_generator import generate_reference

app = FastAPI()

@app.get("/reference/asset-types")
def get_reference():
    return [generate_reference() for _ in range(50)]
