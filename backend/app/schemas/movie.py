# app/schemas/movie.py
from pydantic import BaseModel, ConfigDict
from datetime import date
from typing import Optional, List
from .genre import Genre
from .actor import Actor

class MovieBase(BaseModel):
    title: str
    original_title: Optional[str] = None
    description: Optional[str] = None
    release_year: Optional[int] = None
    release_date: Optional[date] = None
    poster_url: Optional[str] = None
    backdrop_url: Optional[str] = None
    vote_average: Optional[float] = None
    vote_count: Optional[int] = None
    popularity: Optional[float] = None
    runtime: Optional[int] = None
    budget: Optional[int] = None
    revenue: Optional[int] = None
    imdb_id: Optional[str] = None
    status: Optional[str] = None
    tagline: Optional[str] = None

class MovieCreate(MovieBase):
    tmdb_id: Optional[int] = None

class MovieUpdate(MovieBase):
    pass

class Movie(MovieBase):
    id: int
    tmdb_id: Optional[int] = None
    model_config = ConfigDict(from_attributes=True)

# Схема для актёра с ролью в фильме (используется в детальном ответе)
class ActorWithRole(Actor):
    character: Optional[str] = None
    cast_order: Optional[int] = None
    is_lead: Optional[bool] = None

class MovieDetail(Movie):
    genres: List[Genre] = []
    actors: List[ActorWithRole] = []