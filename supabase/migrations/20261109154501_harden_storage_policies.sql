drop policy if exists "avatars: usuarios autenticados" on storage.objects;
drop policy if exists "post-images: usuarios autenticados" on storage.objects;

create policy "avatars: leer autenticados"
on storage.objects for select to authenticated
using (bucket_id = 'avatars');

create policy "avatars: crear en la carpeta propia"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
);

create policy "avatars: actualizar en la carpeta propia"
on storage.objects for update to authenticated
using (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
)
with check (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
);

create policy "avatars: borrar en la carpeta propia"
on storage.objects for delete to authenticated
using (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
);

create policy "post-images: leer autenticados"
on storage.objects for select to authenticated
using (bucket_id = 'post-images');

create policy "post-images: crear en la carpeta propia"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'post-images'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
);

create policy "post-images: actualizar en la carpeta propia"
on storage.objects for update to authenticated
using (
  bucket_id = 'post-images'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
)
with check (
  bucket_id = 'post-images'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
);

create policy "post-images: borrar en la carpeta propia"
on storage.objects for delete to authenticated
using (
  bucket_id = 'post-images'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
);
