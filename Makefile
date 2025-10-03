# test harness made w/ <3 by @stealthybox

# change me
FLUX_264="$(HOME)/.flox/run/aarch64-darwin.default.dev/bin/flux"
FLUX_270="flux"
FLUX_DEV="$(HOME)/repos/fluxcd/flux2/bin/flux"

kind-up:
	scripts/kind-up.sh

kind-down:
	scripts/kind-down.sh

control-plane-shell:
	docker exec -it crd-deprecate-control-plane bash
	# I suggest running `crictl logs -f <api-server container ID>`

# tail apiserver logs :))
tail-apiserver:
	docker exec -it crd-deprecate-control-plane bash -c 'crictl logs -f $$(crictl ps -q --name kube-apiserver)'

flux-2.6.4:
	$(FLUX_264) --version
	$(FLUX_264) install

migrate-all-2.7:
	$(FLUX_270) migrate

flux-2.7.0:
	$(FLUX_270) --version
	$(FLUX_270) install

migrate-dev:
	$(FLUX_DEV) migrate

push-old:
	flux push artifact --path ./old-config oci://localhost:5555/config:latest --source dev --revision dev
	kubectl apply -f ks-config.yaml
	flux reconcile source oci config
	flux reconcile source oci config-copy
	flux reconcile ks config
	flux reconcile ks config-copy

push-new:
	flux push artifact --path ./new-config oci://localhost:5555/config:latest --source dev --revision dev
	kubectl apply -f ks-config.yaml
	flux reconcile source oci config
	flux reconcile source oci config-copy
	flux reconcile ks config
	flux reconcile ks config-copy

push-v1beta3:
	flux push artifact --path ./v1beta3-config oci://localhost:5555/config:latest --source dev --revision dev
	kubectl apply -f ks-config.yaml
	flux reconcile source oci config
	flux reconcile source oci config-copy
	flux reconcile ks config
	flux reconcile ks config-copy

push-annotated:
	flux push artifact --path ./annotated-config oci://localhost:5555/config:latest --source dev --revision dev
	kubectl apply -f ks-config.yaml
	flux reconcile source oci config
	flux reconcile source oci config-copy
	flux reconcile ks config
	flux reconcile ks config-copy

# standalone are working copies of the old and new config
push-standalone: push-standalone-old push-standalone-new

push-standalone-old:
	flux push artifact --path ./old-config oci://localhost:5555/old-config:latest --source dev --revision dev
	kubectl apply -f ks-old-config.yaml
	flux reconcile source oci old-config
	flux reconcile ks old-config

push-standalone-new:
	flux push artifact --path ./new-config oci://localhost:5555/new-config:latest --source dev --revision dev
	kubectl apply -f ks-new-config.yaml
	flux reconcile source oci new-config
	flux reconcile ks new-config

check-inventory:
	kubectl -n flux-system describe ks | grep -e '^Name:' -e 'Id:' -e 'V:'

check-managed-fields-provider:
	kubectl -n flux-system get provider -oyaml --show-managed-fields | grep -E 'v1| kind:| name:|managed'
check-managed-fields-alert:
	kubectl -n flux-system get alert -oyaml --show-managed-fields | grep -E 'v1| kind:| name:|managed'
check-managed-fields-receiver:
	kubectl -n flux-system get receiver -oyaml --show-managed-fields | grep -E 'v1| kind:| name:|managed'

# check for "request to convert CR to an invalid group/version" on dry-run
dry-run-ssa-v1beta3-notify3:
	kubectl apply -f v1beta3-config/notify3.yaml --dry-run=server --server-side

