from sqlalchemy import Column, Integer, ForeignKey, PrimaryKeyConstraint
from ..core.database import Base

class MovieGenre(Base):
    __tablename__ = "movie_genres"
    __table_args__ = (PrimaryKeyConstraint('movie_id', 'genre_id'),)

    movie_id = Column(Integer, ForeignKey("movies.id", ondelete="CASCADE"), nullable=False)
    genre_id = Column(Integer, ForeignKey("genres.id", ondelete="CASCADE"), nullable=False)