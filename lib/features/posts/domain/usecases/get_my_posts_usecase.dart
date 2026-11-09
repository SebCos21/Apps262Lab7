import 'package:moviles_auth/features/posts/data/repository/post_repository_impl.dart';
import 'package:moviles_auth/features/posts/domain/entities/post.dart';
import 'package:moviles_auth/features/posts/domain/repository/post_repository.dart';

/// Brings the latest posts of the signed in user, with their image URLs.
class GetMyPostsUseCase {
  final PostRepository _posts = PostRepositoryImpl();

  Future<List<Post>> call({int limit = 3}) async {
    final posts = await _posts.fetchMine(limit: limit);
    return _withImages(posts);
  }

  Future<List<Post>> _withImages(List<Post> posts) async {
    final paths = posts
        .map((post) => post.imagePath)
        .whereType<String>()
        .toSet()
        .toList();
    if (paths.isEmpty) return posts;

    final urls = await _posts.imageUrls(paths);
    return [
      for (final post in posts)
        if (post.imagePath == null)
          post
        else
          post.copyWith(imageUrl: urls[post.imagePath]),
    ];
  }
}
