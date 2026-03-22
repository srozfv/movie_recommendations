from sqlalchemy import Column, Integer, String, Boolean, ForeignKey, PrimaryKeyConstraint
from ..core.database import Base

class MovieActor(Base):
    __tablename__ = "movie_actors"
    __table_args__ = (PrimaryKeyConstraint('movie_id', 'actor_id'),)

    movie_id = Column(Integer, ForeignKey("movies.id", ondelete="CASCADE"), nullable=False)
    actor_id = Column(Integer, ForeignKey("actors.id", ondelete="CASCADE"), nullable=False)
    character_name = Column(String(500))  # имя персонажа
    cast_order = Column(Integer)          # порядок в титрах
    is_lead = Column(Boolean, default=False)  # главная роль?