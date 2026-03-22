from sqlalchemy import Column, Integer, String, Text, Date
from ..core.database import Base

class Actor(Base):
    __tablename__ = "actors"

    id = Column(Integer, primary_key=True, index=True)
    tmdb_id = Column(Integer, unique=True, nullable=True)
    name = Column(String(200), nullable=False)
    profile_path = Column(String(500))
    biography = Column(Text)
    birthday = Column(Date)
    deathday = Column(Date)
    place_of_birth = Column(String(200))
    gender = Column(Integer)  # 0-неизвестно, 1-женский, 2-мужской