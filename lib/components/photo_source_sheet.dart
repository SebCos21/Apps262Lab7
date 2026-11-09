import 'package:flutter/material.dart';
import 'package:moviles_auth/features/avatar/domain/entities/photo_source.dart';

/// Asks whether the photo comes from the gallery or the camera.
Future<PhotoSource?> showPhotoSourceSheet(
  BuildContext context, {
  String title = 'Agregar foto',
}) {
  return showModalBottomSheet<PhotoSource>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Elegir de la galería'),
              onTap: () => Navigator.pop(context, PhotoSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Tomar una foto'),
              onTap: () => Navigator.pop(context, PhotoSource.camera),
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}
