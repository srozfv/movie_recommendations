from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select, text
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List

from app.core.database import get_db
from app.models.movie import Movie as MovieModel
from app.models.genre import Genre as GenreModel
from app.models.actor import Actor as ActorModel
from app.models.movie_genre import MovieGenre
from app.models.movie_actor import MovieActor
from app.schemas.movie import Movie as MovieSchema
from app.schemas.movie import MovieDetail, ActorWithRole
from app.schemas.genre import Genre as GenreSchema

router = APIRouter()

# ----------------------------------------------------------------------
# 6.8. Популярные фильмы
# ----------------------------------------------------------------------
@router.get("/popular", response_model=List[MovieSchema])
async def get_popular_movies(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db)
):
    """
    Получить список популярных фильмов (сортировка по popularity DESC).
    """
    offset = (page - 1) * page_size
    result = await db.execute(
        select(MovieModel)
        .order_by(MovieModel.popularity.desc())
        .offset(offset)
        .limit(page_size)
    )
    movies = result.scalars().all()
    return movies


# ----------------------------------------------------------------------
# 6.9. Поиск фильмов
# ----------------------------------------------------------------------
@router.get("/search", response_model=List[MovieSchema])
async def search_movies(
    q: str = Query(..., min_length=1, description="Поисковый запрос"),
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db)
):
    """
    Полнотекстовый поиск фильмов по названию и описанию.
    Используется tsvector колонка в таблице movies.
    """
    offset = (page - 1) * page_size
    query = text("""
        SELECT id, tmdb_id, title, original_title, description,
               release_year, release_date, poster_url, backdrop_path,
               vote_average, vote_count, popularity, runtime, budget,
               revenue, imdb_id, status, tagline, tsv, created_at
        FROM movies
        WHERE tsv @@ plainto_tsquery('russian', :query)
        ORDER BY ts_rank(tsv, plainto_tsquery('russian', :query)) DESC
        LIMIT :limit OFFSET :offset
    """)
    result = await db.execute(query, {"query": q, "limit": page_size, "offset": offset})
    rows = result.mappings().all()
    return [MovieSchema.model_validate(dict(row)) for row in rows]


# ----------------------------------------------------------------------
# 6.6. Фильмы по жанрам (для онбординга)
# ----------------------------------------------------------------------
@router.get("/by-genres", response_model=List[MovieSchema])
async def get_movies_by_genres(
    genres: str = Query(..., description="Список ID жанров через запятую, например: 28,12,16"),
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db)
):
    """
    Получить фильмы, принадлежащие хотя бы одному из указанных жанров.
    Используется на втором шаге онбординга.
    """
    genre_ids = [int(g.strip()) for g in genres.split(",") if g.strip()]
    if not genre_ids:
        return []

    # Подзапрос для получения ID фильмов, у которых есть хотя бы один из указанных жанров
    subquery = select(MovieGenre.movie_id).where(MovieGenre.genre_id.in_(genre_ids)).distinct()
    offset = (page - 1) * page_size
    query = (
        select(MovieModel)
        .where(MovieModel.id.in_(subquery))
        .order_by(MovieModel.popularity.desc())
        .offset(offset)
        .limit(page_size)
    )
    result = await db.execute(query)
    movies = result.scalars().all()
    return movies


# ----------------------------------------------------------------------
# 6.4. Детальная информация о фильме (с жанрами и актёрами)
# ----------------------------------------------------------------------
@router.get("/{movie_id}", response_model=MovieDetail)
async def get_movie_detail(
    movie_id: int,
    db: AsyncSession = Depends(get_db)
):
    """
    Получить детальную информацию о фильме по ID,
    включая список жанров и актёров с ролями.
    """
    # Получаем фильм
    movie_result = await db.execute(select(MovieModel).where(MovieModel.id == movie_id))
    movie = movie_result.scalar_one_or_none()
    if not movie:
        raise HTTPException(status_code=404, detail="Фильм не найден")

    # Жанры
    genres_result = await db.execute(
        select(GenreModel)
        .join(MovieGenre, GenreModel.id == MovieGenre.genre_id)
        .where(MovieGenre.movie_id == movie_id)
    )
    genres = genres_result.scalars().all()

    # Актёры с ролями
    actors_result = await db.execute(
        select(ActorModel, MovieActor.character_name, MovieActor.cast_order, MovieActor.is_lead)
        .join(MovieActor, ActorModel.id == MovieActor.actor_id)
        .where(MovieActor.movie_id == movie_id)
        .order_by(MovieActor.cast_order)
    )
    actors = []
    for actor, character, cast_order, is_lead in actors_result:
        actors.append(ActorWithRole(
            id=actor.id,
            tmdb_id=actor.tmdb_id,
            name=actor.name,
            profile_path=actor.profile_path,
            biography=actor.biography,
            birthday=actor.birthday,
            deathday=actor.deathday,
            place_of_birth=actor.place_of_birth,
            gender=actor.gender,
            character=character,
            cast_order=cast_order,
            is_lead=is_lead,
        ))

    # Собираем детальный ответ
    movie_detail = MovieDetail(
        id=movie.id,
        tmdb_id=movie.tmdb_id,
        title=movie.title,
        original_title=movie.original_title,
        description=movie.description,
        release_year=movie.release_year,
        release_date=movie.release_date,
        poster_url=movie.poster_url,
        backdrop_url=movie.backdrop_path,   # используем backdrop_path из модели
        vote_average=movie.vote_average,
        vote_count=movie.vote_count,
        popularity=movie.popularity,
        runtime=movie.runtime,
        budget=movie.budget,
        revenue=movie.revenue,
        imdb_id=movie.imdb_id,
        status=movie.status,
        tagline=movie.tagline,
        genres=genres,
        actors=actors,
    )
    return movie_detail