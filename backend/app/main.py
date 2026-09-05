from fastapi import FastAPI

app = FastAPI(
    title="SmartMind API",
    description="AI Productivity Assistant Backend",
    version="1.0.0"
)       


@app.get("/")
def home():
    return {
        "message": "SmartMind API is running 🚀"
    }