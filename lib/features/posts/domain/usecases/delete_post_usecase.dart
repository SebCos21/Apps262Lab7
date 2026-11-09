import 'package:moviles_auth/features/posts/data/repository/post_repository_impl.dart';
import 'package:moviles_auth/features/posts/domain/entities/post.dart';
import 'package:moviles_auth/features/posts/domain/repository/post_repository.dart';

/// Deletes a post and, if it has one, its image from the private bucket.
class DeletePostUseCase {
  final PostRepository _posts = PostRepositoryImpl();

  Future<void> call(Post post) async {
    await _posts.delete(post.id);

    final path = post.imagePath;
    if (path == null) return;
    try {
      await _posts.deleteImage(path);
    } on Exception {
      // The row is already gone; an orphan file is better than a broken post.
    }
  }
}
