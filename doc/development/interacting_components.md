# Interacting components at GitLab

It's not uncommon that a single code change can reflect and interact with multiple parts of GitLab
codebase, making it possible to break an unrelated feature.

This section goal is to briefly list interacting pieces to reason about
when making _backend_ changes that might involve multiple features or [components].

## Uploads

GitLab supports uploads to [object storage]. That means every feature and change within the upload
realm should also be tested upon it, which is _not_ enabled by default at [GDK].

When working at a related feature, make sure to enable and test it against [Minio] with the following:

```
echo true > object_store_enabled
gdk reconfigure
```

See also:

- [File Storage in GitLab](file_storage.md)


[GDK]: https://gitlab.com/gitlab-org/gitlab-development-kit
[object storage]: https://docs.gitlab.com/charts/advanced/external-object-storage/
[Minio]: https://github.com/minio/minio
[components]: architecture.md#components
