# Laboratorio 7 · Fotos en el muro

Implementación completa del **Laboratorio 7** sobre el proyecto de Supabase del **Laboratorio 5**.

- **Parte 1 · Foto de perfil.** La persona elige una foto de la galería o toma una con la cámara. La foto se sube a un bucket público y aparece en el perfil y junto a cada post suyo.
- **Parte 2 · Posts con imagen.** El composer adjunta una foto, la previsualiza y la publica. Las imágenes de los posts viven en un bucket privado y se muestran con URLs firmadas.

## Proyecto de Supabase

La app apunta al proyecto:

- **URL:** `https://ulpairpampznspjzfmxz.supabase.co`
- **Proyecto:** `Laboratorio5_Apps`
- La `publishable key` está en `lib/main.dart`.

El proyecto remoto ya tiene aplicado:

- `profiles.avatar_path`
- `posts` y `likes`
- `posts.image_path`
- Bucket público `avatars`
- Bucket privado `post-images`
- Policies por carpeta para que cada usuario solo pueda modificar sus propios archivos

Las migraciones locales están en `supabase/migrations/` y el historial remoto quedó alineado.

## Cómo correrlo

```bash
flutter pub get
flutter run -d chrome
```

Para Android:

```bash
flutter devices
flutter run -d <id-del-dispositivo>
```

También se puede instalar el APK generado:

```bash
flutter build apk --debug
# build/app/outputs/flutter-apk/app-debug.apk
```

## Qué incluye

### Parte 1

- Selección de foto desde galería o cámara.
- Redimensionado a 512 px y compresión al 80 %.
- Subida a `avatars/<uid>/<uuid>.<ext>`.
- Validación de tamaño máximo de 2 MB.
- Actualización de `profiles.avatar_path`.
- Borrado del archivo anterior después de actualizar el perfil.
- URL pública del avatar en el perfil y en los posts.
- Indicador de carga mientras sube y SnackBar si falla.
- Botón **Quitar foto** para volver a la inicial.

### Parte 2

- Adjuntar, previsualizar y quitar una foto antes de publicar.
- Publicar con texto y foto, o solo con foto.
- Validación de 280 caracteres y mensaje `Escribe algo o agrega una foto`.
- Subida a `post-images/<uid>/<uuid>.<ext>` antes de insertar el post.
- URL firmada por cada imagen al leer el feed.
- Firma en lote: una sola petición por página con `createSignedUrlsResult`.
- Borrado de posts propios junto con su archivo del bucket.
- Caché en disco con `cached_network_image`; en posts se usa `imagePath` como `cacheKey`.

### Retos implementados

- Policies de Storage por carpeta: cada usuario solo modifica sus archivos.
- Galería o cámara con un enum propio `PhotoSource`, sin filtrar `image_picker` al dominio.
- Quitar la foto de perfil.
- Caché en disco con `cached_network_image`.
- Borrar un post con su imagen.
- Firmar las imágenes del feed en lote.

## Verificación

```bash
flutter analyze
flutter test
flutter build web
flutter build apk --debug
```

El set de tests cubre, además del Laboratorio 6:

- La hoja de selección de galería/cámara en perfil y composer.
- Que el evento lleve la fuente elegida.
- Que el botón de borrar aparezca solo en posts propios.
- Que no aparezca si no hay perfil autenticado.
- Que cancelar el diálogo de borrado no elimine el post.

### Tests de integración

El flujo real de fotos se prueba contra Supabase con una cuenta de prueba. El test sube un avatar, actualiza el perfil, verifica la URL pública, sube una imagen de post, firma en lote, crea y lee el post, y finalmente limpia todo.

```powershell
flutter test test/integration/photo_flow_test.dart `
  --dart-define=TEST_EMAIL=tu-correo-de-prueba `
  --dart-define=TEST_PASSWORD=tu-contrasena-de-prueba
```

Sin `TEST_EMAIL` y `TEST_PASSWORD`, el test se omite y `flutter test` sigue pasando.

## Prueba manual rápida

1. Iniciar sesión.
2. Perfil → cámara → elegir **Galería** o **Cámara**.
3. Cambiar la foto dos veces y verificar que en `avatars` quede solo la última.
4. Publicar un post con texto y foto.
5. Publicar un post solo con foto.
6. Intentar publicar sin texto y sin foto: debe aparecer el error.
7. En el muro, borrar un post propio y confirmar que desaparece el archivo de `post-images`.
8. Verificar que los posts de otras personas no muestran el botón de borrar.
9. Abrir una URL pública de avatar sin sesión: debe verse.
10. Esperar más de una hora y abrir una URL firmada vieja: debe fallar; al recargar el muro se firma de nuevo.
