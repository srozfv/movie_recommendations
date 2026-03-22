# app/schemas/rating.py
from pydantic import BaseModel, ConfigDict
from datetime import datetime
from typing import Optional

class RatingBase(BaseModel):
    rating: int  # 1-10
    is_onboarding: bool = False

class RatingCreate(RatingBase):
    movie_id: int

class RatingUpdate(BaseModel):
    rating: Optional[int] = None

class Rating(RatingBase):
    user_id: int
    movie_id: int
    created_at: datetime
    model_config = ConfigDict(from_attributes=True)