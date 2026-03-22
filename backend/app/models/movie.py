from sqlalchemy import Column, Integer, String, Float, Date, Text, BigInteger, TIMESTAMP
from sqlalchemy.sql import func
from ..core.database import Base
##from sqlalchemy.orm import relationship
from sqlalchemy.dialects.postgresql import TSVECTOR

class Movie(Base):
    __tablename__ = "movies"

    
    ##genres = relationship("Genre", secondary="movie_genres", viewonly=True)
    ##actors = relationship("MovieActor", back_populates="movie")
    id = Column(Integer, primary_key=True, index=True)
    tmdb_id = Column(Integer, unique=True, nullable=True)
    title = Column(String(200), nullable=False)
    original_title = Column(String(200))
    description = Column(Text)
    release_year = Column(Integer)
    release_date = Column(Date)
    poster_url = Column(String(500))
    backdrop_path = Column(String(500))
    vote_average = Column(Float)
    vote_count = Column(Integer)
    popularity = Column(Float)
    runtime = Column(Integer)
    budget = Column(BigInteger)
    revenue = Column(BigInteger)
    imdb_id = Column(String(20))
    status = Column(String(50))
    tagline = Column(Text)
    tsv = Column(Text)  # tsvector для полнотекстового поиска
    created_at = Column(TIMESTAMP, server_default=func.now())
    tsv = Column(TSVECTOR, nullable=True)  # для полнотекстового поиска