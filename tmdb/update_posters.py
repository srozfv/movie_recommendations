import psycopg2
import requests
import time
import sys

# Настройки базы данных (для контейнерной базы)
DB_CONFIG = {
    'dbname': 'cinema',
    'user': 'postgres',
    'password': '2013',
    'host': 'localhost',  # если скрипт запускается на хосте, а БД в контейнере
    'port': 5432
}

# Ваш API-ключ OMDb
OMDB_API_KEY = '56f548d9'  # замените на реальный

def update_posters():
    """Обновляет poster_url для фильмов, у которых есть imdb_id, но нет постера"""
    conn = psycopg2.connect(**DB_CONFIG)
    cur = conn.cursor()
    
    # Получаем фильмы с imdb_id, у которых poster_url пустой или NULL
    cur.execute("""
        SELECT id, imdb_id, title 
        FROM movies 
        WHERE imdb_id IS NOT NULL 
          AND imdb_id != '' 
          AND (poster_url IS NULL OR poster_url = '')
        LIMIT 1000  -- ограничиваем, чтобы не превысить лимит API
    """)
    
    movies = cur.fetchall()
    print(f"Найдено фильмов для обновления: {len(movies)}")
    
    updated = 0
    failed = 0
    
    for movie_id, imdb_id, title in movies:
        try:
            # Запрос к OMDb API
            url = f"http://www.omdbapi.com/?apikey={OMDB_API_KEY}&i={imdb_id}"
            response = requests.get(url, timeout=10)
            data = response.json()
            
            if data.get('Response') == 'True':
                poster_url = data.get('Poster')
                # OMDb возвращает 'N/A' если постера нет
                if poster_url and poster_url != 'N/A':
                    cur.execute(
                        "UPDATE movies SET poster_url = %s WHERE id = %s",
                        (poster_url, movie_id)
                    )
                    conn.commit()
                    updated += 1
                    print(f"✅ {movie_id}: {title} -> {poster_url[:50]}...")
                else:
                    print(f"⚠️ {movie_id}: {title} - постер не найден")
                    # Помечаем, чтобы не запрашивать снова
                    cur.execute(
                        "UPDATE movies SET poster_url = '' WHERE id = %s",
                        (movie_id,)
                    )
                    conn.commit()
                    failed += 1
            else:
                print(f"❌ {movie_id}: {title} - ошибка: {data.get('Error', 'Unknown')}")
                failed += 1
            
            # Пауза, чтобы не превысить лимит (1000 запросов/день)
            time.sleep(0.2)
            
        except Exception as e:
            print(f"💥 Ошибка для {movie_id}: {e}")
            failed += 1
            conn.rollback()
            time.sleep(1)
    
    cur.close()
    conn.close()
    
    print(f"\n📊 Итог: обновлено {updated}, пропущено/ошибок {failed}")

if __name__ == "__main__":
    update_posters()
