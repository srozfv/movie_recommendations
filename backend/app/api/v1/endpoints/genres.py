from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List

from app.core.database import get_db
from app.models.genre import Genre
from app.schemas.genre import Genre as GenreSchema

router = APIRouter()

@router.get("/", response_model=List[GenreSchema])
async def get_genres(db: AsyncSession = Depends(get_db)):
    """
    Получить список всех жанров.
    """
    result = await db.execute(select(Genre).order_by(Genre.name))
    genres = result.scalars().all()
    return genres