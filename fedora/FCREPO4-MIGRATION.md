# Fedora 4 → 6 Data Migration

This directory contains two Docker images for migrating Avalon's Fedora 4
repository to the Fedora 6 OCFL storage format. The migration is a two-phase
process: first export the live Fedora 4 data, then convert that export to the
Fedora 6 OCFL layout.

```
Fedora 4 (live)
       │
       │  fcrepo4-export image
       ▼
 /data/fcrepo4_export/
       │
       │  fcrepo-migrate image  (step 1: F4 → F5)
       ▼
 /data/fcrepo5_export/
       │
       │  fcrepo-migrate image  (step 2: F5 → F6)
       ▼
 /data/fcrepo6_export/   ← load into Fedora 6
```

Both images use `eclipse-temurin:21-jre-jammy` as the base and share a single
`/data` volume so that each phase's output is automatically available as the
next phase's input.

---

## Images

| Image | Dockerfile | Purpose |
|-------|-----------|---------|
| `docker.lib.umd.edu/fcrepo4-export:latest` | `Dockerfile.fcrepo4-export` | Export Fedora 4 content via [fcrepo-import-export 1.2.0](https://github.com/fcrepo-exts/fcrepo-import-export/releases/tag/fcrepo-import-export-1.2.0) |
| `docker.lib.umd.edu/fcrepo-migrate:latest` | `Dockerfile.fcrepo-migrate-4-to-6` | Convert the export to Fedora 6 OCFL via [fcrepo-upgrade-utils 6.3.0-AVALON](https://github.com/avalonmediasystem/fcrepo-upgrade-utils/releases/tag/6.3.0-AVALON) |

### Building

```bash
# From the repo root
docker build -f fedora/Dockerfile.fcrepo4-export \
  -t docker.lib.umd.edu/fcrepo4-export:latest fedora/

docker build -f fedora/Dockerfile.fcrepo-migrate-4-to-6 \
  -t docker.lib.umd.edu/fcrepo-migrate:latest fedora/
```

Building for K8s deployment

```bash
# From the repo root
docker buildx build --no-cache --builder kube --platform linux/amd64 \
    --push -f fedora/Dockerfile.fcrepo4-export \
    -t docker.lib.umd.edu/fcrepo4-export:avalon-$GIT_TAG fedora/

docker buildx build --no-cache --builder kube --platform linux/amd64 \
    --push -f fedora/Dockerfile.fcrepo-migrate-4-to-6 \
    -t docker.lib.umd.edu/fcrepo-migrate:avalon-$GIT_TAG fedora/
```

---

## Phase 1: Export Fedora 4 Content

The `fcrepo4-export` image connects to a **running** Fedora 4 instance and
dumps all RDF resources and binaries to `/data/fcrepo4_export/`.

> **Note:** Fedora 4's REST path is `/fedora/rest`; Fedora 6 uses `/fcrepo/rest`.

### Environment variables

| Variable | Default | Description |
|----------|---------|-------------|
| `FEDORA_URL` | `http://fedora:8080/fedora/rest` | Fedora 4 REST API base URL |
| `FEDORA_USER` | `fedoraAdmin` | Fedora admin username |
| `FEDORA_PASSWORD` | `fedoraAdmin` | Fedora admin password |
| `EXPORT_DIR` | `/data/fcrepo4_export` | Directory to write export output |
| `DATA_DIR` | `/data` | Root of the mounted volume (logs are written here) |

### Volume layout produced

```
/data/
  fcrepo4_export/          ← RDF and binary export output
  export_<timestamp>.log   ← full export log
  remaining_<timestamp>.log  ← written only if export was interrupted
```

### Running against a docker-compose stack

```bash
docker run --rm \
  --network avalon_internal \
  -e FEDORA_URL=http://fedora:8080/fedora/rest \
  -e FEDORA_USER=fedoraAdmin \
  -e FEDORA_PASSWORD=fedoraAdmin \
  -v /path/to/data:/data \
  docker.lib.umd.edu/fcrepo4-export:latest
```

The compose project network is named `<project>_internal`. The default project
name is the containing directory (e.g. `avalon_internal`). Override with
`-p myproject` or the `COMPOSE_PROJECT_NAME` environment variable.

### Running standalone (Fedora 4 accessible on host)

```bash
docker run --rm \
  -e FEDORA_URL=http://host.docker.internal:8080/fedora/rest \
  -e FEDORA_USER=fedoraAdmin \
  -e FEDORA_PASSWORD=fedoraAdmin \
  -v /path/to/data:/data \
  docker.lib.umd.edu/fcrepo4-export:latest
```

### Resume after interruption

If the export is interrupted, a `remaining_<timestamp>.log` file is written to
`/data`. Re-run the container with the **same volume** and the script will
automatically detect the remaining file and resume:

```bash
# Same command as the original run — no extra flags needed
docker run --rm \
  --network avalon_internal \
  -e FEDORA_URL=http://fedora:8080/fedora/rest \
  -e FEDORA_USER=fedoraAdmin \
  -e FEDORA_PASSWORD=fedoraAdmin \
  -v /path/to/data:/data \
  docker.lib.umd.edu/fcrepo4-export:latest
```

---

## Phase 2: Migrate Export to Fedora 6 OCFL

The `fcrepo-migrate` image runs entirely offline against the `/data` volume —
it **does not connect to any Fedora instance**. `BASE_URI` is only embedded into
the OCFL metadata as the canonical resource identifier.

The migration is a two-step process:

1. **F4 → F5** — converts Fedora 4.7.5 export format to Fedora 5 intermediate format
2. **F5 → F6** — converts the F5 intermediate to a Fedora 6 OCFL repository

If a step has already completed (detected via a done-marker file in `/data`),
it is skipped on re-run.

### Environment variables

| Variable | Default | Description |
|----------|---------|-------------|
| `BASE_URI` | `http://fedora:8080/fcrepo/rest` | Fedora 6 REST base URI embedded in OCFL metadata |
| `DATA_DIR` | `/data` | Root of the mounted volume |
| `INPUT_DIR` | `/data/fcrepo4_export` | Fedora 4 export input (from Phase 1) |
| `F5_DIR` | `/data/fcrepo5_export` | F5 intermediate output directory |
| `F6_DIR` | `/data/fcrepo6_export` | F6 OCFL output directory |

### Volume layout consumed/produced

```
/data/
  fcrepo4_export/            ← input (from Phase 1)
  fcrepo5_export/            ← F5 intermediate (created by step 1)
  fcrepo6_export/            ← F6 OCFL store   (created by step 2)
  upgrade_5_<timestamp>.log  ← step 1 log
  upgrade_6_<timestamp>.log  ← step 2 log
  .f4_to_f5_complete         ← done-marker for step 1
  .f5_to_f6_complete         ← done-marker for step 2
  remaining_f4_to_f5_*.log   ← written if step 1 was interrupted
  remaining_f5_to_f6_*.log   ← written if step 2 was interrupted
```

### Running the migration

The `/data` volume must contain the `fcrepo4_export/` directory produced by
Phase 1 before running this image.

```bash
docker run --rm \
  -e BASE_URI=http://fedora:8080/fcrepo/rest \
  -v /path/to/data:/data \
  docker.lib.umd.edu/fcrepo-migrate:latest
```

### Resume after interruption

Re-run the container with the same volume. The script detects
`remaining_f4_to_f5_*.log` or `remaining_f5_to_f6_*.log` files and resumes the
interrupted step. Completed steps (marked by `.f4_to_f5_complete` /
`.f5_to_f6_complete`) are skipped automatically.

```bash
# Same command as the original run — no extra flags needed
docker run --rm \
  -e BASE_URI=http://fedora:8080/fcrepo/rest \
  -v /path/to/data:/data \
  docker.lib.umd.edu/fcrepo-migrate:latest
```

---

## Kubernetes Jobs

K8s Job manifests are maintained in the `k8s-avalon` repository:

- `k8s/fcrepo4-export-job.yaml` — runs Phase 1 as a K8s Job
- `k8s/fcrepo-migrate-job.yaml` — runs Phase 2 as a K8s Job

---

## Full Migration Walkthrough

### 1. Provision a shared data volume

The same persistent volume must be mounted by both jobs.

```bash
mkdir -p /mnt/fcrepo-migration
```

### 2. Run the export (Phase 1)

```bash
docker run --rm \
  --network avalon_internal \
  -e FEDORA_URL=http://fedora:8080/fedora/rest \
  -e FEDORA_USER=fedoraAdmin \
  -e FEDORA_PASSWORD=fedoraAdmin \
  -v /mnt/fcrepo-migration:/data \
  docker.lib.umd.edu/fcrepo4-export:latest
```

On success the log ends with:

```
[...] Export completed successfully. Output: /data/fcrepo4_export
```

### 3. Run the migration (Phase 2)

```bash
docker run --rm \
  -e BASE_URI=http://fedora:8080/fcrepo/rest \
  -v /mnt/fcrepo-migration:/data \
  docker.lib.umd.edu/fcrepo-migrate:latest
```

On success the log ends with:

```
[...] Migration complete. Fedora 6 OCFL data is in: /data/fcrepo6_export
[...] Next step: sync /data/fcrepo6_export/data/ocfl-root to your Fedora 6 storage.
```

### 4. Load the OCFL store into Fedora 6

Copy or sync `/mnt/fcrepo-migration/fcrepo6_export/data/ocfl-root` to the
storage location configured for your Fedora 6 instance, then restart Fedora 6.

---

## Reference

- [Avalon Fedora Migration Guide](https://samvera.atlassian.net/wiki/spaces/AVALON/pages/2808086529)
- [fcrepo-import-export](https://github.com/fcrepo-exts/fcrepo-import-export)
- [fcrepo-upgrade-utils (Avalon fork)](https://github.com/avalonmediasystem/fcrepo-upgrade-utils)
