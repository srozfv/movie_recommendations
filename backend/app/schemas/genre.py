# app/schemas/genre.py
from pydantic import BaseModel, ConfigDict

class GenreBase(BaseModel):
    name: str
    tmdb_id: int | None = None

class GenreCreate(GenreBase):
    pass

class GenreUpdate(GenreBase):
    pass

class Genre(GenreBase):
    id: int
    model_config = ConfigDict(from_attributes=True)