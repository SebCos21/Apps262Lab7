import 'package:moviles_auth/features/avatar/domain/entities/photo_source.dart';
import 'package:moviles_auth/features/avatar/domain/entities/picked_photo.dart';
import 'package:moviles_auth/features/posts/data/repository/post_repository_impl.dart';
import 'package:moviles_auth/features/posts/domain/repository/post_repository.dart';

/// Picks the photo of a new post and checks that it is not too heavy.
class PickPostImageUseCase {
  static const maxBytes = 2 * 1024 * 1024;

  final PostRepository _posts = PostRepositoryImpl();

  Future<PickedPhoto?> call({PhotoSource source = PhotoSource.gallery}) async {
    final photo = await _posts.pickImage(source: source);
    if (photo == null) return null;
    if (photo.bytes.length > maxBytes) {
      throw Exception('La foto pesa más de 2 MB');
    }
    return photo;
  }
}
