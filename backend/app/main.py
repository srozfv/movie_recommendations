from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api.v1.endpoints import movies, genres, auth, recommendations

app = FastAPI(title="Cinema API", version="1.0.0")

# Настройка CORS (разрешаем доступ из Flutter приложения)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # для разработки, позже можно ограничить
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(movies.router, prefix="/api/v1/movies", tags=["movies"])
app.include_router(genres.router, prefix="/api/v1/genres", tags=["genres"])
app.include_router(auth.router, prefix="/api/v1/auth", tags=["auth"])
app.include_router(recommendations.router, prefix="/api/v1/recommendations", tags=["recommendations"])