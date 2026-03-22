# app/schemas/actor.py
from pydantic import BaseModel, ConfigDict
from datetime import date
from typing import Optional

class ActorBase(BaseModel):
    name: str
    tmdb_id: Optional[int] = None
    profile_path: Optional[str] = None
    biography: Optional[str] = None
    birthday: Optional[date] = None
    deathday: Optional[date] = None
    place_of_birth: Optional[str] = None
    gender: Optional[int] = None

class ActorCreate(ActorBase):
    pass

class ActorUpdate(ActorBase):
    pass

class Actor(ActorBase):
    id: int
    model_config = ConfigDict(from_attributes=True)