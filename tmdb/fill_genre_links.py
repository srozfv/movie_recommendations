import psycopg2
import requests
import time

# Настройки базы данных
DB_CONFIG = {
    'dbname': 'cinema',
    'user': 'postgres',
    'password': '2013',
    'host': 'localhost',
    'port': 5432
}

# TMDb API ключ (используйте тот же, что в load_tmdb.py)
TMDB_API_KEY = '9fd82a6234cafc824fecc2c1d93e2c52'

def fill_movie_genres():
    conn = psycopg2.connect(**DB_CONFIG)
    cur = conn.cursor()
    
    # Получаем все фильмы, у которых есть tmdb_id
    cur.execute("SELECT id, tmdb_id FROM movies WHERE tmdb_id IS NOT NULL")
    movies = cur.fetchall()
    print(f"Найдено фильмов: {len(movies)}")
    
    total_links = 0
    
    for movie_id, tmdb_id in movies:
        try:
            # Запрос к TMDb для получения жанров фильма
            url = f"https://api.themoviedb.org/3/movie/{tmdb_id}?api_key={TMDB_API_KEY}&language=ru-RU"
            response = requests.get(url, timeout=10)
            data = response.json()
            
            if data.get('genres'):
                for genre in data['genres']:
                    # Получаем внутренний id жанра по tmdb_id
                    cur.execute("SELECT id FROM genres WHERE tmdb_id = %s", (genre['id'],))
                    genre_row = cur.fetchone()
                    if genre_row:
                        genre_id = genre_row[0]
                        cur.execute("""
                            INSERT INTO movie_genres (movie_id, genre_id)
                            VALUES (%s, %s)
                            ON CONFLICT DO NOTHING
                        """, (movie_id, genre_id))
                        total_links += 1
            
            conn.commit()
            print(f"✅ Фильм {movie_id}: добавлено жанров")
            time.sleep(0.1)  # пауза, чтобы не превысить лимиты
            
        except Exception as e:
            print(f"❌ Ошибка для фильма {movie_id}: {e}")
            conn.rollback()
    
    cur.close()
    conn.close()
    print(f"\n📊 Всего добавлено связей: {total_links}")

if __name__ == "__main__":
    fill_movie_genres()
