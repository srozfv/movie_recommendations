from sqlalchemy import Column, Integer, SmallInteger, TIMESTAMP, Boolean, ForeignKey, PrimaryKeyConstraint
from sqlalchemy.sql import func
from ..core.database import Base

class Rating(Base):
    __tablename__ = "ratings"
    __table_args__ = (PrimaryKeyConstraint('user_id', 'movie_id'),)

    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    movie_id = Column(Integer, ForeignKey("movies.id", ondelete="CASCADE"), nullable=False)
    rating = Column(SmallInteger, nullable=False)  # 1-10
    is_onboarding = Column(Boolean, default=False)
    created_at = Column(TIMESTAMP, server_default=func.now())