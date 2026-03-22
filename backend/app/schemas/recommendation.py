# app/schemas/recommendation.py
from pydantic import BaseModel
from typing import List, Dict

class RecommendationRequest(BaseModel):
    genre_ids: List[int] = []
    ratings: Dict[int, int] = {}  # movie_id -> rating (1-10)