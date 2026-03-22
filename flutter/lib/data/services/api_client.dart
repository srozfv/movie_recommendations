import 'package:dio/dio.dart';
import '../models/movie.dart';
import '../models/genre.dart';
import '../models/user.dart';
import '../models/token.dart';
import '../../core/services/token_service.dart';

class ApiClient {
  final Dio _dio;
  final TokenService _tokenService;

 // Future<List<ActorWithRole>> getMovieCast(int movieId) async {
  //  final response = await _dio.get('/movies/$movieId/actors');
   // return (response.data as List).map((json) => ActorWithRole.fromJson(json)).toList();
 // }

  ApiClient({required String baseUrl})
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {'Content-Type': 'application/json'},
        )),
        _tokenService = TokenService() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _tokenService.getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        return handler.next(error);
      },
    ));
  }

  // Аутентификация
  Future<Token> register(String username, String email, String password) async {
    final request = RegisterRequest(username: username, email: email, password: password);
    print('📤 Регистрация: ${request.toJson()}');
    try {
      final response = await _dio.post('/auth/register', data: request.toJson());
      print('✅ Регистрация успешна: ${response.data}');
      return Token.fromJson(response.data);
    } on DioException catch (e) {
      print('❌ Ошибка регистрации: ${e.response?.statusCode}');
      print('📥 Ответ сервера: ${e.response?.data}');
      rethrow;
    }
  }

  Future<Token> login(String email, String password) async {
    print('📤 Логин: username=$email, password=$password');
    try {
      final response = await _dio.post(
        '/auth/login',
        data: FormData.fromMap({
          'username': email,
          'password': password,
        }),
        options: Options(
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
          },
        ),
      );
      print('✅ Логин успешен: ${response.data}');
      return Token.fromJson(response.data);
    } on DioException catch (e) {
      print('❌ Ошибка логина: ${e.response?.statusCode}');
      print('📥 Ответ сервера: ${e.response?.data}');
      rethrow;
    }
  }

  // Фильмы
  Future<List<Movie>> getPopularMovies({int page = 1}) async {
    print('📤 Запрос популярных фильмов, page=$page');
    try {
      final response = await _dio.get('/movies/popular', queryParameters: {'page': page});
      print('✅ Ответ сервера: ${response.data}'); // <- здесь response определён
      return (response.data as List).map((json) => Movie.fromJson(json)).toList();
    } catch (e) {
      print('❌ Ошибка загрузки популярных фильмов: $e');
      rethrow;
    }
  }

  Future<List<Movie>> searchMovies(String query) async {
    final response = await _dio.get('/movies/search', queryParameters: {'q': query});
    return (response.data as List).map((json) => Movie.fromJson(json)).toList();
  }

  Future<Movie> getMovieDetail(int movieId) async {
    final response = await _dio.get('/movies/$movieId');
    return Movie.fromJson(response.data);
  }

  // Жанры
  Future<List<Genre>> getGenres() async {
    final response = await _dio.get('/genres');
    return (response.data as List).map((json) => Genre.fromJson(json)).toList();
  }

  // Фильмы по жанрам
  Future<List<Movie>> getMoviesByGenres(List<int> genreIds, {int page = 1}) async {
    final response = await _dio.get('/movies/by-genres', queryParameters: {
      'genres': genreIds.join(','),
      'page': page,
    });
    return (response.data as List).map((json) => Movie.fromJson(json)).toList();
  }

  // Рекомендации
  Future<List<Movie>> getRecommendations(List<int> genreIds, Map<int, int> ratings) async {
    final response = await _dio.post('/recommendations', data: {
      'genre_ids': genreIds,
      'ratings': ratings.entries.map((e) => {'movieId': e.key, 'rating': e.value}).toList(),
    });
    return (response.data as List).map((json) => Movie.fromJson(json)).toList();
  }
}