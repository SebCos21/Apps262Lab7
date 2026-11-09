import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:moviles_auth/features/auth/data/source/supabase_profile_data_source.dart';
import 'package:moviles_auth/features/avatar/data/source/supabase_avatar_data_source.dart';
import 'package:moviles_auth/features/avatar/domain/entities/picked_photo.dart';
import 'package:moviles_auth/features/posts/data/source/supabase_post_data_source.dart';
import 'package:moviles_auth/features/posts/data/source/supabase_post_image_data_source.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _url = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://ulpairpampznspjzfmxz.supabase.co',
);
const _key = String.fromEnvironment(
  'SUPABASE_KEY',
  defaultValue: 'sb_publishable_Gc3_kYl9dKfmMRDKIPi_Ug_cSMznq6N',
);
const _email = String.fromEnvironment('TEST_EMAIL');
const _password = String.fromEnvironment('TEST_PASSWORD');

final _photo = PickedPhoto(
  bytes: Uint8List.fromList(const [
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
    0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
    0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0xF8, 0xCF, 0xC0, 0xF0,
    0x1F, 0x00, 0x05, 0x00, 0x01, 0xFF, 0x89, 0x99, 0x3D, 0x1D, 0x00, 0x00,
    0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
  ]),
  extension: 'png',
);

void main() {
  final configured = _email.isNotEmpty && _password.isNotEmpty;

  group('flujo completo de fotos', () {
    late SupabaseClient client;
    late String uid;
    late SupabaseAvatarDataSource avatars;
    late SupabaseProfileDataSource profiles;
    late SupabasePostImageDataSource images;
    late SupabasePostDataSource posts;
    String? originalAvatarPath;

    setUpAll(() async {
      client = SupabaseClient(_url, _key);
      final auth = await client.auth.signInWithPassword(
        email: _email,
        password: _password,
      );
      uid = auth.user!.id;
      avatars = SupabaseAvatarDataSource(client: client);
      profiles = SupabaseProfileDataSource(client: client);
      images = SupabasePostImageDataSource(client: client);
      posts = SupabasePostDataSource(client: client);
      originalAvatarPath = (await profiles.getProfile(uid)).avatarPath;
    });

    tearDownAll(() async {
      await client.auth.signOut();
      await client.dispose();
    });

    test('perfil: subir avatar, apuntar el path, URL pública y limpiar', () async {
      String? path;
      try {
        path = await avatars.upload(_photo);
        expect(path, startsWith('$uid/'));

        await profiles.updateAvatarPath(uid, path);
        final profile = await profiles.getProfile(uid);
        expect(profile.avatarPath, path);
        expect(profile.avatarUrl, isNotNull);
        expect(await _status(profile.avatarUrl!), HttpStatus.ok);
      } finally {
        await profiles.updateAvatarPath(uid, originalAvatarPath);
        if (path != null) await _ignore(() => avatars.remove(path!));
      }
    });

    test('post: subir imagen, firmar en lote, crear, leer y borrar', () async {
      String? path;
      String? postId;
      try {
        path = await images.upload(_photo);

        final urls = await images.signedUrls([path]);
        expect(urls[path], isNotNull);
        expect(await _status(urls[path]!), HttpStatus.ok);

        final publicUrl = client.storage
            .from(SupabasePostImageDataSource.bucket)
            .getPublicUrl(path);
        expect(await _status(publicUrl), isNot(HttpStatus.ok));

        await posts.create('', imagePath: path);
        final mine = await posts.fetchMine(limit: 1);
        expect(mine, isNotEmpty);
        postId = mine.first.id;
        expect(mine.first.imagePath, path);
      } finally {
        if (postId != null) await _ignore(() => posts.delete(postId!));
        if (path != null) await _ignore(() => images.remove(path!));
      }
    });
  }, skip: configured ? null : 'Define TEST_EMAIL y TEST_PASSWORD');
}

Future<int> _status(String url) async {
  final client = HttpClient();
  try {
    final request = await client.getUrl(Uri.parse(url));
    final response = await request.close();
    await response.drain<void>();
    return response.statusCode;
  } finally {
    client.close(force: true);
  }
}

Future<void> _ignore(Future<void> Function() action) async {
  try {
    await action();
  } on Exception {
    // Cleanup is best effort; a failed cleanup must not hide the test result.
  }
}
