import 'package:moviles_auth/features/avatar/domain/entities/photo_source.dart';

/// Something the compose screen asks the ComposeBloc to do.
abstract class ComposeEvent {}

/// The user wants to attach a photo from the gallery or the camera.
class ComposePhotoRequested extends ComposeEvent {
  final PhotoSource source;

  ComposePhotoRequested({this.source = PhotoSource.gallery});

  @override
  String toString() {
    return 'ComposePhotoRequested(${source.name})';
  }
}

/// The user removed the attached photo.
class ComposePhotoRemoved extends ComposeEvent {
  @override
  String toString() {
    return 'ComposePhotoRemoved()';
  }
}

/// The user pressed Publicar with this text.
class ComposeSubmitted extends ComposeEvent {
  final String content;

  ComposeSubmitted(this.content);

  @override
  String toString() {
    return "ComposeSubmitted('$content')";
  }
}
