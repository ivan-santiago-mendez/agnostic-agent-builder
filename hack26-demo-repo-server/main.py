from fastapi import FastAPI

app = FastAPI(title="hack26-demo-repo-server", version="0.1.0", description="Hackathon demo server")


@app.get("/hello")
async def hello():
    return {"message": "Hello, World!"}
