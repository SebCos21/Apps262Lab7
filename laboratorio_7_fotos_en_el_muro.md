# Laboratorio 7 · Fotos en el muro

El muro del Laboratorio 6 funciona, pero todos aparecen con una letra en vez de una cara, y los posts solo tienen texto. Este laboratorio tiene dos partes:

* **Parte 1 · Foto de perfil.** Cada persona sube su foto desde la galería. La foto aparece en su perfil y junto a cada post suyo.
* **Parte 2 · Posts con imagen (avanzada).** El composer deja adjuntar una foto al post.

Las fotos de perfil van en un **bucket público**: cada una tiene una URL fija que cualquiera puede abrir. Las de los posts van en un **bucket privado**: solo quien inició sesión las ve, con URLs firmadas.

## Lo que vas a construir

> **Descripción de la imagen:** Un diagrama explicativo dividido en tres secciones. A la izquierda (`HomeScreen` > `ProfilePage`), se muestra la pantalla de perfil con un avatar de usuario y un botón de cámara flotante. Una flecha morada indica que al presionarlo se abre el selector de imágenes del sistema (mostrado en el centro, `image_picker` > `galería del sistema`), el cual muestra una cuadrícula con imágenes recientes y la aclaración de que "no es de la app: la abre el sistema". Al seleccionar una foto, otra flecha la conecta con la vista del muro a la derecha (`HomeScreen` > `FeedPage`), donde los posts de los usuarios ahora muestran la fotografía correspondiente junto a su nombre de usuario. Al pie se indica: *"Mientras sube, la foto del perfil muestra un indicador de carga. Si algo falla, un SnackBar dice por qué."*

---

## Preparación

El punto de partida es este proyecto: [github.com/Domiciano/Apps262Lab7](https://github.com/Domiciano/Apps262Lab7). Es el Laboratorio 6 resuelto, más toda la interfaz de las fotos.

```bash
git clone https://github.com/Domiciano/Apps262Lab7
cd Apps262Lab7
flutter pub get
```

Pon en `lib/main.dart` la `Project URL` y la `publishable key` de tu proyecto de Supabase. Usa el mismo proyecto de los laboratorios 5 y 6: ya tiene las tablas, las cuentas y los posts.

## Conectar con tu proyecto de Supabase

El repositorio no trae la carpeta `supabase/`: es de cada quien. Créala y conéctala desde la carpeta `Apps262Lab7`, como en Configurando los servicios:

```bash
npx supabase login
npx supabase init
npx supabase link --project-ref TU_IDENTIFICADOR
```

`login` solo hace falta si nunca lo corriste en este computador. El identificador es el de tu proyecto, el mismo del Laboratorio 6.

Tu proyecto ya tiene aplicadas las migraciones de `profiles`, `posts` y `likes`, pero la carpeta nueva no las conoce. Tráelas:

```bash
npx supabase migration fetch --linked
```

Aparece un archivo por migración en `supabase/migrations/`. Sin ellos, el `db push` del paso 2 se niega con `Remote migration versions not found in local migrations directory`.

Por último, `init` crea un `config.toml` largo que ya trae una sección `[storage]`. Si en el paso 1 le agregas otra, el archivo queda inválido. Reemplaza todo su contenido por el del curso:

```toml
project_id = "Apps262Lab7"

[auth]
enabled = true

[auth.email]
enable_signup = true
enable_confirmations = false
```

Comprueba que todo coincida. Las tres migraciones deben aparecer en las dos columnas, la local y la remota:

```bash
npx supabase migration list
```

---

## Lo que ya viene

> **Descripción de la imagen:** Un esquema detallado en forma de árbol del directorio `lib/` del proyecto. Los elementos en gris indican lo que ya viene hecho, y los números en círculos naranjas señalan la parte del laboratorio en la que se completan. Se destacan los componentes de `avatar/` y `posts/` (como `usecases`, `data sources`, `repositories`, `blocs` y `screens`), especificando qué parte del código o lógica debe implementar el estudiante en cada archivo.

* La interfaz completa. `Avatar` pinta la foto, o la inicial si no hay. `ProfilePage` tiene el botón de cámara, `ComposeScreen` el botón Agregar foto, la vista previa y Quitar foto, y `PostCard` la imagen del post.
* Las entidades y los contratos. `PickedPhoto` (los bytes y la extensión), `Profile` con `avatarPath` y `avatarUrl`, `Post` con `authorAvatarUrl` e `imageUrl`. `AvatarRepository`, `ProfileRepository` y `PostRepository` ya declaran todo lo que el laboratorio pide.
* Los eventos y los estados. `AvatarChangeRequested`, `ComposePhotoRequested`, `ComposePhotoRemoved`, `FeedState.avatarStatus` y `ComposeState.photo`.
* Los métodos vacíos. Cada método nuevo de cada capa ya existe con su firma, pero su cuerpo es `throw UnimplementedError()`. Los `on` nuevos de los Bloc solo imprimen el evento.

Los dos botones de foto, el de la cámara del perfil y Agregar foto del composer, todavía no lanzan su evento: su callback es `() {}`.

Tu trabajo es reemplazar cada `throw UnimplementedError()` por su código, de afuera hacia adentro, y al final conectar los botones.

---

## Parte 1 · Foto de perfil

Del paso 1 al 10. Al terminar, cada persona tiene su foto en el perfil y en sus posts.

### Paso 1 · El bucket avatars

> **Descripción de la imagen:** Un diagrama conceptual que ilustra la estructura de la base de datos y el almacenamiento. Muestra la tabla `profiles` con sus campos (`id`, `username`, `full_name`, `avatar_path`), conectada mediante una flecha al bucket de almacenamiento `avatars` (configurado en `config.toml` como público, con límite de 2 MiB y tipos permitidos `jpeg`, `png`, `webp`). A la derecha, muestra un cuadro con la política de seguridad requerida: `for all to authenticated` con `bucket_id = 'avatars'`. Abajo, un recuadro aclara que `avatar_path` empieza en `null` si el usuario no ha subido foto, y la app muestra la inicial del nombre.

Al final de `supabase/config.toml`:

```toml
[storage]
enabled = true

[storage.buckets.avatars]
public = true
file_size_limit = "2MiB"
allowed_mime_types = ["image/jpeg", "image/png", "image/webp"]
```

Créalo en tu proyecto:

```bash
npx supabase seed buckets --linked
```

En el dashboard, `Storage` muestra `avatars` con la etiqueta *Public*.

---

### Paso 2 · La columna y la regla

```bash
npx supabase migration new create_avatars
```

```sql
alter table public.profiles add column avatar_path text;

create policy "avatars: usuarios autenticados"
on storage.objects for all to authenticated
using (bucket_id = 'avatars')
with check (bucket_id = 'avatars');
```

```bash
npx supabase db push
```

Que el bucket sea público solo abre la lectura por URL. Subir y borrar necesitan política, y basta una: abre todo a quien inició sesión.

---

### Paso 3 · Elegir la foto

`avatar/data/source/device_photo_data_source.dart` es el único archivo que importa `image_picker`. Abre la galería y traduce el `XFile` que devuelve a un `PickedPhoto`:

```dart
final ImagePicker _picker = ImagePicker();

Future<PickedPhoto?> pick() async {
  final file = await _picker.pickImage(
    source: ImageSource.gallery,
    maxWidth: 512,
    maxHeight: 512,
    imageQuality: 80,
  );
  if (file == null) return null;
  return PickedPhoto(
    bytes: await file.readAsBytes(),
    extension: file.name.split('.').last.toLowerCase(),
  );
}
```

---

### Paso 4 · Subir y borrar en Storage

`avatar/data/source/supabase_avatar_data_source.dart` es el único archivo que usa el bucket `avatars`. Agrega los campos y completa `upload`:

```dart
final SupabaseClient _client = Supabase.instance.client;
final Uuid _uuid = const Uuid();

String get _uid {
  return _client.auth.currentUser!.id;
}

Future<String> upload(PickedPhoto photo) async {
  final path = '${_uid}/${_uuid.v4()}.${photo.extension}';
  final type = photo.extension == 'jpg' ? 'jpeg' : photo.extension;
  try {
    await _client.storage.from(bucket).uploadBinary(
      path,
      photo.bytes,
      fileOptions: FileOptions(
        contentType: 'image/$type',
        cacheControl: '31536000',
      ),
    );
    return path;
  } on StorageException catch (e) {
    throw Exception(e.message);
  }
}
```

`remove` es más corto: `_client.storage.from(bucket).remove([path])` dentro del mismo `try`. El nombre es un UUID nuevo en cada subida, así la foto nueva nunca se confunde con la vieja en ninguna caché.

---

### Paso 5 · El repositorio

`avatar/data/repository/avatar_repository_impl.dart` crea los dos data sources como campos y delega en ellos:

```dart
final DevicePhotoDataSource _device = DevicePhotoDataSource();
final SupabaseAvatarDataSource _storage = SupabaseAvatarDataSource();
```

`pick` va a `_device`, `upload` y `remove` van a `_storage`. Cada método queda de una línea, con `return`.

---

### Paso 6 · El caso de uso

> **Descripción de la imagen:** Un diagrama secuencial numerado del 1 al 6 que detalla el flujo de `ChangeAvatarUseCase`: 1. `AvatarRepository.pick()` (si la persona cancela, no sigue). 2. `ProfileRepository.getProfile(id)` (recuerda el `avatarPath` anterior). 3. `AvatarRepository.upload(photo)` (nombre nuevo, devuelve el path). 4. `ProfileRepository.updateAvatarPath(id, path)` (el perfil apunta a la foto nueva). 5. `AvatarRepository.remove(oldPath)` (solo si había una foto antes). 6. `ProfileRepository.getProfile(id)` (el perfil con su `avatarUrl` nueva). Abajo se incluye una regla de dominio: *"Si la foto pesa más de 2 MB, el caso de uso lanza su propio mensaje sin ir hasta Storage."*

`avatar/domain/usecases/change_avatar_usecase.dart`:

```dart
static const maxBytes = 2 * 1024 * 1024;
final AuthRepository _auth = AuthRepositoryImpl();
final ProfileRepository _profiles = ProfileRepositoryImpl();
final AvatarRepository _avatars = AvatarRepositoryImpl();

Future<Profile?> call() async {
  final user = _auth.currentUser();
  if (user == null) throw Exception('No hay una sesión iniciada');
  final photo = await _avatars.pick();
  if (photo == null) return null;
  if (photo.bytes.length > maxBytes) {
    throw Exception('La foto pesa más de 2 MB');
  }
  final before = await _profiles.getProfile(user.id);
  final path = await _avatars.upload(photo);
  await _profiles.updateAvatarPath(user.id, path);
  final oldPath = before?.avatarPath;
  if (oldPath != null) await _avatars.remove(oldPath);
  return _profiles.getProfile(user.id);
}
```

El orden importa: primero sube, después apunta y al final borra. Si algo falla a mitad, sobra un archivo, pero el perfil nunca apunta a una foto que no existe.

---

### Paso 7 · El perfil

En `auth/data/source/supabase_profile_data_source.dart`, completa `updateAvatarPath`:

```dart
Future<void> updateAvatarPath(String id, String path) async {
  try {
    await _client
        .from('profiles')
        .update({'avatar_path': path})
        .eq('id', id);
  } on PostgrestException catch (e) {
    throw Exception(e.message);
  }
}
```

En `getProfile`, lee `avatar_path` y arma su URL pública. Agrega estos dos campos al `Profile` que ya devuelve:

```dart
final path = row['avatar_path'] as String?;

avatarPath: path,
avatarUrl: path == null
    ? null
    : _client.storage.from('avatars').getPublicUrl(path),
```

En `auth/data/repository/profile_repository_impl.dart`, `updateAvatarPath` delega en el data source.

---

### Paso 8 · Las fotos del muro

En `posts/data/source/supabase_post_data_source.dart`, pide `avatar_path` en las columnas del autor:

```dart
'author:profiles!profile_id(username, full_name, avatar_path), '
```

Y en `_toPost`, arma su URL igual que en el perfil:

```dart
final avatarPath = author['avatar_path'] as String?;

authorAvatarUrl: avatarPath == null
    ? null
    : _client.storage.from('avatars').getPublicUrl(avatarPath),
```

`getPublicUrl` no va a la red: solo arma el texto de la URL. Por eso alcanza para todos los posts de la página sin hacer más peticiones. Si el autor no tiene foto, queda `null` y `Avatar` muestra la inicial.

---

### Paso 9 · FeedBloc

En `home/ui/bloc/feed_bloc.dart`, crea el caso de uso como campo, `final ChangeAvatarUseCase _changeAvatar = ChangeAvatarUseCase();`, y reemplaza el `debugPrint`:

```dart
emit(state.copyWith(avatarStatus: AvatarStatus.uploading));
try {
  final profile = await _changeAvatar();
  if (profile == null) {
    emit(state.copyWith(avatarStatus: AvatarStatus.idle));
    return;
  }
  emit(state.copyWith(profile: profile, avatarStatus: AvatarStatus.idle));
  add(FeedStarted());
} on Exception catch (e) {
  emit(state.copyWith(
    avatarStatus: AvatarStatus.failure,
    errorMessage: _message(e),
  ));
}
```

`add(FeedStarted())` recarga el muro para que tus posts muestren la foto nueva.

---

### Paso 10 · El botón del perfil

Falta el primer tramo del camino: de la pantalla al Bloc. En `home/ui/screens/home_screen.dart`, `ProfilePage` recibe `onChangePhoto: () {}`. Haz que lance el evento, igual que `onLike` lanza el suyo:

```dart
onChangePhoto: () => bloc.add(AvatarChangeRequested()),
```

La pantalla no abre la galería ni sube nada: solo avisa que la persona quiere otra foto. La galería la abre el data source del paso 3.

Corre la app, toca la cámara del perfil y elige una foto.

---

## La prueba de la parte 1

* Sube una foto. En `storage > avatars` aparece una carpeta con tu id y un archivo con nombre de UUID. En `profiles`, `avatar_path` tiene ese path.
* Cambia la foto dos veces. La app muestra la última y en tu carpeta queda un solo archivo.
* Desde otra cuenta, tus posts muestran tu foto. Los de quien no tiene foto, su inicial.
* Toca la cámara y cierra la galería sin elegir: no pasa nada.
* Abre la URL de tu foto en el navegador, sin sesión: se ve, porque `avatars` es público.

---

## Parte 2 · Posts con imagen (avanzada)

> **Descripción de la imagen:** Un diagrama ilustrando el funcionamiento de la Parte 2. Muestra un post nuevo en `ComposeScreen` con texto y una tarjeta de imagen adjunta que incluye un botón "X" para quitarla, junto con el botón inferior "Publicar". Una flecha lo vincula con la vista del muro (`HomeScreen` > `FeedPage`) donde aparece el post con la imagen adjunta. A la derecha, un diagrama de flujo titulado `PUBLISHPOSTUSECASE, EN ORDEN` detalla 3 pasos: 1. Valida texto o foto (máximo 280 caracteres). 2. `uploadImage(photo)` (sube a `post-images` y devuelve el path). 3. `create(text, imagePath: path)` (inserta en la tabla `posts`). Debajo se incluye una advertencia: *"La foto sube primero. Si sube y el insert falla, sobra un archivo. Al revés quedaría un post sin su imagen."*

Del paso 11 al 15. Reutiliza lo de la parte 1: el mismo data source del teléfono y el mismo patrón de subida. Lo nuevo es que este bucket es **privado**: la base de datos guarda el path de cada imagen, y para mostrarla hay que pedir una URL firmada. Eso lo hace el caso de uso: trae los posts y completa cada uno con la URL de su imagen.

---

### Paso 11 · El bucket post-images

Al final de `supabase/config.toml`:

```toml
[storage.buckets.post-images]
public = false
file_size_limit = "2MiB"
allowed_mime_types = ["image/jpeg", "image/png", "image/webp"]
```

```bash
npx supabase seed buckets --linked
npx supabase migration new create_post_images
```

```sql
alter table public.posts add column image_path text;

create policy "post-images: usuarios autenticados"
on storage.objects for all to authenticated
using (bucket_id = 'post-images')
with check (bucket_id = 'post-images');
```

```bash
npx supabase db push
```

---

### Paso 12 · Los datos

`posts/data/source/supabase_post_image_data_source.dart` tiene dos métodos. `upload` es igual al paso 4, con `bucket = 'post-images'`. `signedUrl` pide a Storage una URL firmada para un path:

```dart
Future<String> signedUrl(String path) async {
  try {
    return await _client.storage.from(bucket).createSignedUrl(path, 3600);
  } on StorageException catch (e) {
    throw Exception(e.message);
  }
}
```

En `posts/data/repository/post_repository_impl.dart`, crea dos campos más y delega en ellos. El data source del teléfono es el mismo de la parte 1:

```dart
final DevicePhotoDataSource _device = DevicePhotoDataSource();
final SupabasePostImageDataSources _images = SupabasePostImageDataSource();
```

`pickImage` va a `_device`, `uploadImage` a `_images.upload` e `imageUrl` a `_images.signedUrl`.

En `posts/data/source/supabase_post_data_source.dart`, `create` agrega `'image_path': imagePath` al `insert`, las columnas piden `image_path` y `_toPost` lo pasa a la entidad tal cual, sin firmarlo:

```dart
'id, content, image_path, created_at, '

imagePath: row['image_path'] as String?,
```

El data source no arma la URL: solo trae lo que hay en la tabla.

---

### Paso 13 · Los casos de uso

`GetFeedUseCase` y `GetMyPostsUseCase` traen los posts de la base de datos y después completan cada uno con la URL de su imagen. En `posts/domain/usecases/get_feed_usecase.dart`:

```dart
Future<List<Post>> call({required int page, required int size}) async {
  final posts = await _posts.fetchFeed(page: page, size: size);
  return Future.wait(posts.map(_withImage));
}

Future<Post> _withImage(Post post) async {
  final path = post.imagePath;
  if (path == null) return post;
  return post.copyWith(imageUrl: await _posts.imageUrl(path));
}
```

* `_withImage` deja igual el post sin imagen. Al que tiene, le pide la URL al repositorio y la pone con `copyWith`.
* `Future.wait` pide todas las URL de la página al mismo tiempo, en vez de esperar una por una.
* El caso de uso no sabe que la URL es firmada: solo pide `imageUrl`. Cómo se obtiene es asunto de la capa de datos.

`GetMyPostsUseCase` es igual, con `fetchMine(limit: limit)`.

`posts/domain/usecases/pick_post_image_usecase.dart` pide la foto y revisa su peso:

```dart
static const maxBytes = 2 * 1024 * 1024;
final PostRepository _posts = PostRepositoryImpl();

Future<PickedPhoto?> call() async {
  final photo = await _posts.pickImage();
  if (photo == null) return null;
  if (photo.bytes.length > maxBytes) {
    throw Exception('La foto pesa más de 2 MB');
  }
  return photo;
}
```

`posts/domain/usecases/publish_post_usecase.dart` ya trae la validación del Laboratorio 6. Cámbiala para que un post pueda ser solo una foto, y sube la foto antes de crear el post:

```dart
Future<void> call(String content, {PickedPhoto? photo}) async {
  final text = content.trim();
  if (text.isEmpty && photo == null) {
    throw Exception('Escribe algo o agrega una foto');
  }
  if (text.length > maxLength) {
    throw Exception('Máximo $maxLength caracteres');
  }
  final imagePath =
      photo == null ? null : await _posts.uploadImage(photo);
  await _posts.create(text, imagePath: imagePath);
}
```

---

### Paso 14 · ComposeBloc

En `compose/ui/bloc/compose_bloc.dart`, crea `final PickPostImageUseCase _pickImage = PickPostImageUseCase();` y completa los dos `on` de la foto:

```dart
Future<void> _onPhotoRequested(
  ComposePhotoRequested event,
  Emitter<ComposeState> emit,
) async {
  try {
    final photo = await _pickImage();
    if (photo == null) return;
    emit(state.copyWith(status: ComposeStatus.initial, photo: photo));
  } on Exception catch (e) {
    emit(state.copyWith(
      status: ComposeStatus.failure,
      errorMessage: e.toString().replaceFirst('Exception: ', ''),
    ));
  }
}
```

`_onPhotoRemoved` emite `state.copyWith(removePhoto: true)`: un `copyWith` normal no puede volver `null` un campo, por eso el estado trae esa bandera. En `_onSubmitted`, pasa la foto al publicar: `await _publish(event.content, photo: state.photo);`.

---

### Paso 15 · El botón del composer

En `compose/ui/screens/compose_screen.dart`, el botón Agregar foto tiene `onPressed: () {}`. Haz que lance el evento del composer:

```dart
onPressed: () =>
    context.read<ComposeBloc>().add(ComposePhotoRequested()),
```

---

## La prueba de la parte 2

* Adjunta una foto, quítala y adjunta otra. La vista previa sigue lo que haces.
* Publica con texto y foto, y luego solo con foto. Los dos aparecen en el muro con su imagen.
* Publica sin texto y sin foto: aparece `Escribe algo o agrega una foto`.
* En `storage > post-images` hay una carpeta con tu id. En `posts`, `image_path` tiene el path.
* Copia la URL de una imagen, espera más de una hora y ábrela: responde `"exp" claim timestamp check failed`. Al recargar el muro se firma de nuevo.

---

## Retos

* **Cada quien en su carpeta.** Con la regla mínima, cualquiera con sesión puede borrar la foto de otra persona. Cambia la política para que borrar solo se permita si `(storage.foldername(name))[1] = (select auth.uid()::text)`.
* **Galería o cámara.** Una hoja con Elegir de la galería y Tomar una foto. El evento lleva la opción, pero el dominio no puede recibir `ImageSource`, que es de `image_picker`: define un `enum PhotoSource { gallery, camera }` propio y tradúcelo en el data source.
* **Quitar la foto de perfil.** Un botón que borra el archivo y deja `avatar_path` en `null`.
* **Caché en disco.** Cambia `Image.network` por `cached_network_image`. ¿Sirve de algo con URLs firmadas que cambian cada vez?
* **Borrar un post con imagen.** Al borrar el post, borra también su archivo del bucket.
* **Firmar en lote.** El muro pide una URL por imagen. Con `createSignedUrlsResult(paths, 3600)`, Storage firma todos los paths de la página en una sola petición.