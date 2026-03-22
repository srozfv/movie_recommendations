#!/usr/bin/env python
# -*- coding: utf-8 -*-

import psycopg2
from tmdbv3api import TMDb, Movie, Genre, Person, Discover
import time
import logging
from datetime import datetime

# ========== НАСТРОЙКИ ==========
TMDB_API_KEY = '9fd82a6234cafc824fecc2c1d93e2c52'
DB_CONFIG = {
    'dbname': 'cinema',
    'user': 'postgres',
    'password': '2013',
    'host': 'db',
    'port': 5432
}

MAX_MOVIES = 50000  # желаемое максимальное количество фильмов (можно None)
PAUSE_BETWEEN_MOVIES = 0.2  # пауза после каждого фильма (сек)
PAUSE_BETWEEN_PAGES = 0.5   # пауза между страницами

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

# ========== ИНИЦИАЛИЗАЦИЯ TMDb ==========
tmdb = TMDb()
tmdb.api_key = TMDB_API_KEY
tmdb.language = 'ru-RU'
tmdb.debug = False

movie_api = Movie()
genre_api = Genre()
person_api = Person()
discover = Discover()

# ========== ПОДКЛЮЧЕНИЕ К БД ==========
def get_connection():
    return psycopg2.connect(**DB_CONFIG)

# ========== ЗАГРУЗКА ЖАНРОВ ==========
def load_genres(conn):
    logging.info("Загрузка жанров...")
    genres = genre_api.movie_list()
    with conn.cursor() as cur:
        for g in genres:
            cur.execute("SELECT id FROM genres WHERE tmdb_id = %s", (g.id,))
            if not cur.fetchone():
                cur.execute("INSERT INTO genres (name, tmdb_id) VALUES (%s, %s)", (g.name, g.id))
        conn.commit()
    logging.info(f"Загружено {len(genres)} жанров.")

# ========== ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ==========
def fetch_movie_details(movie_id):
    try:
        return movie_api.details(movie_id)
    except Exception as e:
        logging.error(f"Ошибка получения деталей фильма {movie_id}: {e}")
        return None

def fetch_movie_credits(movie_id):
    try:
        return movie_api.credits(movie_id)
    except Exception as e:
        logging.error(f"Ошибка получения актёров для фильма {movie_id}: {e}")
        return None

def get_or_create_actor(conn, cast):
    with conn.cursor() as cur:
        cur.execute("SELECT id FROM actors WHERE tmdb_id = %s", (cast.id,))
        row = cur.fetchone()
        if row:
            return row[0]
        else:
            cur.execute("""
                INSERT INTO actors (tmdb_id, name, profile_path, gender)
                VALUES (%s, %s, %s, %s)
                RETURNING id
            """, (cast.id, cast.name, cast.profile_path, cast.gender))
            return cur.fetchone()[0]

def get_genre_internal_id(conn, tmdb_genre_id):
    with conn.cursor() as cur:
        cur.execute("SELECT id FROM genres WHERE tmdb_id = %s", (tmdb_genre_id,))
        row = cur.fetchone()
        return row[0] if row else None

# ========== ЗАГРУЗКА ОДНОГО ФИЛЬМА ==========
def load_single_movie(conn, tmdb_id):
    """Загружает один фильм. Возвращает True, если фильм был добавлен (новый)."""
    details = fetch_movie_details(tmdb_id)
    if not details:
        return False

    try:
        with conn.cursor() as cur:
            cur.execute("""
                INSERT INTO movies (
                    tmdb_id, title, original_title, description, release_date,
                    budget, revenue, runtime, vote_average, vote_count, popularity,
                    poster_url, backdrop_path, imdb_id, status, tagline
                ) VALUES (
                    %(id)s, %(title)s, %(original_title)s, %(overview)s, %(release_date)s,
                    %(budget)s, %(revenue)s, %(runtime)s, %(vote_average)s, %(vote_count)s,
                    %(popularity)s, %(poster_path)s, %(backdrop_path)s, %(imdb_id)s,
                    %(status)s, %(tagline)s
                )
                ON CONFLICT (tmdb_id) DO UPDATE SET
                    title = EXCLUDED.title,
                    vote_average = EXCLUDED.vote_average,
                    vote_count = EXCLUDED.vote_count,
                    popularity = EXCLUDED.popularity
                RETURNING id
            """, details)
            movie_row = cur.fetchone()
            if not movie_row:
                return False
            movie_pk = movie_row[0]
            is_new = cur.rowcount == 1  # если была вставка, а не обновление

            # Жанры
            if hasattr(details, 'genre_ids') and details.genre_ids:
                for tmdb_genre_id in details.genre_ids:
                    genre_internal_id = get_genre_internal_id(conn, tmdb_genre_id)
                    if genre_internal_id:
                        cur.execute("""
                            INSERT INTO movie_genres (movie_id, genre_id)
                            VALUES (%s, %s)
                            ON CONFLICT DO NOTHING
                        """, (movie_pk, genre_internal_id))

            # Актёры
            credits = fetch_movie_credits(tmdb_id)
            if credits and hasattr(credits, 'cast'):
                for idx, cast in enumerate(credits.cast):
                    actor_pk = get_or_create_actor(conn, cast)
                    is_lead = idx < 5
                    cur.execute("""
                        INSERT INTO movie_actors (movie_id, actor_id, character_name, cast_order, is_lead)
                        VALUES (%s, %s, %s, %s, %s)
                        ON CONFLICT (movie_id, actor_id) DO UPDATE SET
                            character_name = EXCLUDED.character_name,
                            cast_order = EXCLUDED.cast_order,
                            is_lead = EXCLUDED.is_lead
                    """, (movie_pk, actor_pk, cast.character, idx, is_lead))

            conn.commit()
            return is_new

    except Exception as e:
        conn.rollback()
        logging.error(f"Ошибка при вставке фильма {tmdb_id}: {e}")
        return False

# ========== ЗАГРУЗКА ИЗ СПИСКА ID ==========
def load_movies_from_id_list(conn, id_list, source_name):
    """Загружает фильмы из списка ID, возвращает количество новых."""
    count = 0
    for idx, tmdb_id in enumerate(id_list):
        if MAX_MOVIES and get_total_movies(conn) >= MAX_MOVIES:
            logging.info(f"Достигнут лимит {MAX_MOVIES} фильмов, остановка.")
            break
        if load_single_movie(conn, tmdb_id):
            count += 1
        time.sleep(PAUSE_BETWEEN_MOVIES)
        if (idx + 1) % 10 == 0:
            logging.info(f"{source_name}: обработано {idx+1} фильмов, новых {count}")
    logging.info(f"{source_name}: загружено {count} новых фильмов")
    return count

def get_total_movies(conn):
    with conn.cursor() as cur:
        cur.execute("SELECT COUNT(*) FROM movies")
        return cur.fetchone()[0]

# ========== ЗАГРУЗКА ПО ГОДАМ ==========
def load_by_year(conn, start_year, end_year, max_pages=10):
    """Загружает фильмы по годам, для каждого года до max_pages страниц."""
    total_new = 0
    for year in range(start_year, end_year + 1):
        if MAX_MOVIES and get_total_movies(conn) >= MAX_MOVIES:
            break
        logging.info(f"Год {year}: начало загрузки")
        page = 1
        year_new = 0
        while page <= max_pages:
            try:
                movies = discover.discover_movies({
                    'primary_release_year': year,
                    'sort_by': 'popularity.desc',
                    'page': page
                })
                if not movies:
                    break
                ids = [m.id for m in movies]
                new_in_page = 0
                for tmdb_id in ids:
                    if MAX_MOVIES and get_total_movies(conn) >= MAX_MOVIES:
                        break
                    if load_single_movie(conn, tmdb_id):
                        new_in_page += 1
                        total_new += 1
                        year_new += 1
                    time.sleep(PAUSE_BETWEEN_MOVIES)
                logging.info(f"Год {year}, стр {page}: загружено {new_in_page} новых")
                page += 1
                time.sleep(PAUSE_BETWEEN_PAGES)
            except Exception as e:
                logging.error(f"Ошибка при получении страницы {page} для года {year}: {e}")
                break
        logging.info(f"Год {year}: всего новых {year_new}")
    return total_new

# ========== ЗАГРУЗКА ИЗ ПОПУЛЯРНЫХ/ТОП/И Т.Д. ==========
def load_from_list_endpoint(conn, endpoint_func, name, pages=5):
    """Загружает из эндпоинта, возвращающего список фильмов (popular, top_rated, ...)"""
    total_new = 0
    for page in range(1, pages + 1):
        if MAX_MOVIES and get_total_movies(conn) >= MAX_MOVIES:
            break
        try:
            movies = endpoint_func(page=page)
            if not movies:
                break
            ids = [m.id for m in movies]
            new_in_page = 0
            for tmdb_id in ids:
                if MAX_MOVIES and get_total_movies(conn) >= MAX_MOVIES:
                    break
                if load_single_movie(conn, tmdb_id):
                    new_in_page += 1
                    total_new += 1
                time.sleep(PAUSE_BETWEEN_MOVIES)
            logging.info(f"{name}, страница {page}: новых {new_in_page}")
            time.sleep(PAUSE_BETWEEN_PAGES)
        except Exception as e:
            logging.error(f"Ошибка при получении {name} страницы {page}: {e}")
            break
    logging.info(f"{name}: загружено новых {total_new}")
    return total_new

# ========== ЗАГРУЗКА ПО ЖАНРАМ ==========
def load_by_genre(conn, pages_per_genre=3):
    """Для каждого жанра загружает популярные фильмы."""
    with conn.cursor() as cur:
        cur.execute("SELECT tmdb_id FROM genres WHERE tmdb_id IS NOT NULL")
        genre_ids = [row[0] for row in cur.fetchall()]
    total_new = 0
    for gid in genre_ids:
        if MAX_MOVIES and get_total_movies(conn) >= MAX_MOVIES:
            break
        logging.info(f"Жанр {gid}: загрузка")
        for page in range(1, pages_per_genre + 1):
            try:
                movies = discover.discover_movies({
                    'with_genres': gid,
                    'sort_by': 'popularity.desc',
                    'page': page
                })
                if not movies:
                    break
                ids = [m.id for m in movies]
                new_in_page = 0
                for tmdb_id in ids:
                    if MAX_MOVIES and get_total_movies(conn) >= MAX_MOVIES:
                        break
                    if load_single_movie(conn, tmdb_id):
                        new_in_page += 1
                        total_new += 1
                    time.sleep(PAUSE_BETWEEN_MOVIES)
                logging.info(f"Жанр {gid}, стр {page}: новых {new_in_page}")
                time.sleep(PAUSE_BETWEEN_PAGES)
            except Exception as e:
                logging.error(f"Ошибка при получении жанра {gid} страницы {page}: {e}")
                break
    return total_new

# ========== ОСНОВНАЯ ФУНКЦИЯ ==========
def main():
    conn = get_connection()
    try:
        # Сначала жанры (обязательно)
        load_genres(conn)

        # Подсчитаем текущее количество фильмов
        initial_count = get_total_movies(conn)
        logging.info(f"Текущее количество фильмов в БД: {initial_count}")

        # 1. Загрузка по годам (основной источник)
        # Для старых лет меньше страниц, для новых больше
        # 1970-1999: по 5 страниц
        # 2000-2026: по 15 страниц
        total_new = 0
        total_new += load_by_year(conn, 1998, 1999, max_pages=5)
        if not MAX_MOVIES or get_total_movies(conn) < MAX_MOVIES:
            total_new += load_by_year(conn, 2007, 2026, max_pages=15)

        # 2. Популярные, топ, сейчас в прокате, предстоящие (по 10 страниц каждого)
        if not MAX_MOVIES or get_total_movies(conn) < MAX_MOVIES:
            total_new += load_from_list_endpoint(conn, movie_api.popular, "popular", pages=10)
        if not MAX_MOVIES or get_total_movies(conn) < MAX_MOVIES:
            total_new += load_from_list_endpoint(conn, movie_api.top_rated, "top_rated", pages=10)
        if not MAX_MOVIES or get_total_movies(conn) < MAX_MOVIES:
            total_new += load_from_list_endpoint(conn, movie_api.now_playing, "now_playing", pages=5)
        if not MAX_MOVIES or get_total_movies(conn) < MAX_MOVIES:
            total_new += load_from_list_endpoint(conn, movie_api.upcoming, "upcoming", pages=5)

        # 3. По жанрам (по 3 страницы на жанр)
        if not MAX_MOVIES or get_total_movies(conn) < MAX_MOVIES:
            total_new += load_by_genre(conn, pages_per_genre=3)

        final_count = get_total_movies(conn)
        logging.info(f"Загрузка завершена! Было: {initial_count}, стало: {final_count}, новых: {total_new}")

    except Exception as e:
        logging.exception("Критическая ошибка")
    finally:
        conn.close()

if __name__ == "__main__":
    main()
