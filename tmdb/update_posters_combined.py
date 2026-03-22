import psycopg2
import requests
import time
import urllib.parse
import sys

# ========== НАСТРОЙКИ ==========
# Настройки базы данных (для контейнерной базы)
DB_CONFIG = {
    'dbname': 'cinema',
    'user': 'postgres',
    'password': '2013',
    'host': 'localhost',  # если скрипт на хосте, а БД в контейнере
    'port': 5432
}

# API-ключи (заменены на ваши)
KP_API_KEY = '834aa59d-c8ef-4331-9841-acda5f673342'   # ваш ключ Кинопоиска
OMDB_API_KEY = '2481a807'                              # ваш ключ OMDb

# ========== ФУНКЦИИ ДЛЯ ПОЛУЧЕНИЯ ПОСТЕРОВ ==========
def get_poster_from_kinopoisk(title, year):
    """
    Получает постер из Кинопоиска по названию и году.
    Возвращает кортеж (poster_url, kinopoisk_id)
    """
    try:
        # Формируем поисковый запрос
        query = f"{title} {year if year else ''}".strip()
        encoded_query = urllib.parse.quote(query)
        url = f"https://kinopoiskapiunofficial.tech/api/v2.1/films/search-by-keyword?keyword={encoded_query}&page=1"
        
        headers = {'X-API-KEY': KP_API_KEY}
        response = requests.get(url, headers=headers, timeout=10)
        data = response.json()
        
        if data.get('films') and len(data['films']) > 0:
            film = data['films'][0]
            poster_url = film.get('posterUrl')
            kinopoisk_id = film.get('kinopoiskId')
            return poster_url, kinopoisk_id
    except Exception as e:
        print(f"  Ошибка Кинопоиска: {e}")
    
    return None, None

def get_poster_from_imdb(imdb_id, title):
    """
    Получает постер из IMDb через OMDb API.
    Возвращает URL постера или None
    """
    try:
        if imdb_id and imdb_id != '':
            url = f"http://www.omdbapi.com/?apikey={OMDB_API_KEY}&i={imdb_id}"
        else:
            encoded_title = urllib.parse.quote(title)
            url = f"http://www.omdbapi.com/?apikey={OMDB_API_KEY}&t={encoded_title}"
        
        response = requests.get(url, timeout=10)
        data = response.json()
        
        if data.get('Response') == 'True' and data.get('Poster') != 'N/A':
            return data['Poster']
    except Exception as e:
        print(f"  Ошибка IMDb: {e}")
    
    return None

# ========== ОСНОВНАЯ ФУНКЦИЯ ==========
def update_all_posters(limit=500):
    """
    Обновляет постеры для фильмов, у которых их нет.
    limit – количество фильмов за один запуск (чтобы не превысить лимиты API)
    """
    conn = psycopg2.connect(**DB_CONFIG)
    cur = conn.cursor()
    
    # Получаем фильмы без постера
    cur.execute("""
        SELECT id, title, release_year, imdb_id 
        FROM movies 
        WHERE (poster_url IS NULL OR poster_url = '')
        LIMIT %s
    """, (limit,))
    
    movies = cur.fetchall()
    print(f"\n📊 Найдено фильмов для обновления: {len(movies)}")
    print("=" * 60)
    
    updated = 0
    not_found = 0
    errors = 0
    
    for idx, (movie_id, title, year, imdb_id) in enumerate(movies, 1):
        print(f"\n[{idx}/{len(movies)}] {movie_id}: {title} ({year or 'год неизвестен'})")
        
        poster_url = None
        kinopoisk_id = None
        
        # 1. Пробуем Кинопоиск
        print("  🔍 Поиск в Кинопоиске...")
        poster_url, kinopoisk_id = get_poster_from_kinopoisk(title, year)
        
        # 2. Если не нашлось, пробуем IMDb
        if not poster_url:
            print("  🔍 Поиск в IMDb...")
            poster_url = get_poster_from_imdb(imdb_id, title)
        
        # 3. Обновляем базу данных
        if poster_url:
            try:
                if kinopoisk_id:
                    cur.execute("""
                        UPDATE movies 
                        SET poster_url = %s, kinopoisk_id = %s 
                        WHERE id = %s
                    """, (poster_url, kinopoisk_id, movie_id))
                else:
                    cur.execute("""
                        UPDATE movies 
                        SET poster_url = %s 
                        WHERE id = %s
                    """, (poster_url, movie_id))
                
                conn.commit()
                updated += 1
                print(f"  ✅ Успешно! Постер сохранён")
                print(f"     URL: {poster_url[:80]}...")
            except Exception as e:
                conn.rollback()
                errors += 1
                print(f"  ❌ Ошибка сохранения в БД: {e}")
        else:
            not_found += 1
            print(f"  ❌ Постер не найден")
            
            # Помечаем, чтобы не запрашивать снова
            try:
                cur.execute(
                    "UPDATE movies SET poster_url = '' WHERE id = %s",
                    (movie_id,)
                )
                conn.commit()
            except:
                pass
        
        # Пауза, чтобы не превысить лимиты API
        time.sleep(0.3)
    
    cur.close()
    conn.close()
    
    # Вывод статистики
    print("\n" + "=" * 60)
    print(f"📊 СТАТИСТИКА:")
    print(f"   ✅ Обновлено: {updated}")
    print(f"   ❌ Не найдено: {not_found}")
    print(f"   💥 Ошибок: {errors}")
    print("=" * 60)

# ========== ТЕСТОВАЯ ФУНКЦИЯ (для проверки подключения) ==========
def test_connection():
    """Проверяет подключение к базе данных и API"""
    print("🔍 Проверка подключения к базе данных...")
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        cur = conn.cursor()
        cur.execute("SELECT COUNT(*) FROM movies")
        count = cur.fetchone()[0]
        print(f"✅ База данных доступна, в ней {count} фильмов")
        cur.close()
        conn.close()
    except Exception as e:
        print(f"❌ Ошибка подключения к БД: {e}")
        return False
    
    print("\n🔍 Проверка API Кинопоиска...")
    try:
        headers = {'X-API-KEY': KP_API_KEY}
        response = requests.get(
            "https://kinopoiskapiunofficial.tech/api/v2.1/films/search-by-keyword?keyword=avatar&page=1",
            headers=headers,
            timeout=10
        )
        if response.status_code == 200:
            print("✅ API Кинопоиска работает")
        else:
            print(f"⚠️ API Кинопоиска вернул статус {response.status_code}")
    except Exception as e:
        print(f"❌ Ошибка API Кинопоиска: {e}")
    
    print("\n🔍 Проверка API IMDb (OMDb)...")
    try:
        response = requests.get(
            f"http://www.omdbapi.com/?apikey={OMDB_API_KEY}&t=avatar",
            timeout=10
        )
        if response.status_code == 200:
            data = response.json()
            if data.get('Response') == 'True':
                print("✅ API IMDb работает")
            else:
                print(f"⚠️ API IMDb вернул ошибку: {data.get('Error')}")
        else:
            print(f"⚠️ API IMDb вернул статус {response.status_code}")
    except Exception as e:
        print(f"❌ Ошибка API IMDb: {e}")
    
    return True

# ========== ТОЧКА ВХОДА ==========
if __name__ == "__main__":
    print("\n" + "=" * 60)
    print("🎬 СКРИПТ ЗАГРУЗКИ ПОСТЕРОВ (Кинопоиск + IMDb)")
    print("=" * 60)
    
    # Проверяем подключения
    if not test_connection():
        print("\n❌ Не удалось подключиться к базе данных. Проверьте настройки DB_CONFIG.")
        sys.exit(1)
    
    # Запускаем обновление
    print("\n🚀 Начинаем загрузку постеров...")
    print("   (можно прервать Ctrl+C)")
    
    try:
        update_all_posters(limit=800)
        print("\n✅ Скрипт завершён!")
        print("\n💡 Совет: Запустите скрипт несколько раз, чтобы обновить все фильмы")
    except KeyboardInterrupt:
        print("\n\n⚠️ Скрипт прерван пользователем")
    except Exception as e:
        print(f"\n❌ Критическая ошибка: {e}")
