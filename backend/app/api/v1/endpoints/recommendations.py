from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List

from app.core.database import get_db
from app.models.movie import Movie
from app.schemas.movie import Movie as MovieSchema
from app.schemas.recommendation import RecommendationRequest

router = APIRouter()

@router.post("/", response_model=List[MovieSchema])
async def get_recommendations(
    request: RecommendationRequest,
    db: AsyncSession = Depends(get_db)
):
    """
    Получить персональные рекомендации на основе выбранных жанров и оценок.
    Пока возвращает популярные фильмы (заглушка).
    """
    # Здесь будет логика рекомендаций. Пока просто популярные.
    result = await db.execute(
        select(Movie).order_by(Movie.popularity.desc()).limit(20)
    )
    movies = result.scalars().all()
    return movies