from sqlalchemy import Column, Integer, String
from ..core.database import Base

class Genre(Base):
    __tablename__ = "genres"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), nullable=False, unique=True)
    tmdb_id = Column(Integer, unique=True, nullable=True)