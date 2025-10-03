### some quick repro commands:

repro:
stale v1beta1 field managers  + v1beta3 & v1 inventories  , pre-upgrade:

```bash
make kind-up flux-2.6.4 push-old check-inventory && flux get ks && make push-v1beta3 check-inventory && flux get ks
```

reproduce 2.7.0 upgrade failure:

`Error from server: request to convert CR to an invalid group/version: notification.toolkit.fluxcd.io/v1beta1`
```bash
make kind-up flux-2.6.4 push-old check-inventory && flux get ks && make push-v1beta3 check-inventory && flux get ks && make migrate-all-2.7 && flux reconcile ks config && make flux-2.7.0 && flux get ks
```


### notes
[2.7-crd-migration-notes.md](2.7-crd-migration-notes.md)


### flux2 cli migrate.go git diff
```diff
diff --git cmd/flux/migrate.go cmd/flux/migrate.go
index 4c304a72..f1219f45 100644
--- cmd/flux/migrate.go
+++ cmd/flux/migrate.go
@@ -140,6 +140,14 @@ func (m *Migrator) migrateCR(ctx context.Context, crd *apiextensionsv1.CustomRes
        apiVersion := crd.Spec.Group + "/" + version
        listKind := crd.Spec.Names.ListKind

+       switch listKind {
+       case "AlertList":
+       // case "ProviderList":
+       // case "ReceiverList":
+       default:
+               return nil
+       }
+
        list.SetAPIVersion(apiVersion)
        list.SetKind(listKind)

@@ -152,12 +160,13 @@ func (m *Migrator) migrateCR(ctx context.Context, crd *apiextensionsv1.CustomRes
                return nil
        }

+       i := 0
        for _, item := range list.Items {
                // patch the resource with an empty patch to update the version
                if err := m.kubeClient.Patch(
                        ctx,
                        &item,
-                       client.RawPatch(client.Merge.Type(), []byte("{}")),
+                       client.RawPatch(client.Merge.Type(), []byte("{\"metadata\":{\"annotations\":{\"upgrade.fluxcd.io/version\":\"v2.7.0\"}}}")),
                ); err != nil && !apierrors.IsNotFound(err) {
                        return fmt.Errorf(" %s/%s/%s failed to migrate: %w",
                                item.GetKind(), item.GetNamespace(), item.GetName(), err)
@@ -165,6 +174,12 @@ func (m *Migrator) migrateCR(ctx context.Context, crd *apiextensionsv1.CustomRes

                logger.Successf("%s/%s/%s migrated to version %s",
                        item.GetKind(), item.GetNamespace(), item.GetName(), version)
+
+               i += 1
+               if i == 1 {
+                       logger.Successf("Exiting early after %d iterations 👋", i)
+                       return nil
+               }
        }

        return nil
```

