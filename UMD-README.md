# UMD avalon-docker

This UMD-provided README.md describes using the Docker images provided by
this repository with the UMD Avalon local development environment in
the [umd-lib/avalon](https://github.com/umd-lib/avalon) repository and with
the Kubernetes configurations in the
[umd-lib/k8s-avalon](https://github.com/umd-lib/k8s-avalon) repository.

## About the Docker images

Both the UMD Avalon local development environment and Kubernetes configuration
use images built from this repository.

The UMD Avalon stack consists of

* Customized Docker images built from this repository (HLS nginx)
* Stock Docker images used directly without retagging (db, Fedora, Solr, Redis)
* Docker images not provided by Avalon

Custom images should be built using "docker buildx" and the Kubernetes
"build" namespace. See
<https://github.com/umd-lib/devops/blob/main/k8s/docs/guides/DockerBuilds.md>
in Confluence for more information.

The Docker images are built with the "linux/amd64" architecture, so that they
are compatible with the nodes running in Kubernetes. As of July 2025, it is
not possible to build most of these images using the "linux/arm64" architecture,
as the required base images do not support ARM. The "linux/amd64" Docker images
will work on Apple Silicon MacBooks, however there may be a significant
performance impact using a stock Docker Desktop implementation (it is strongly
suggested that Orb Stack <https://orbstack.dev/> be used instead).

## Git Tagging the Docker Image

The Docker images created from this repository are used in the
"docker-compose.yml" file in the "umd-lib/avalon" repository for local
development, and in the "kustomization.yaml" files in the "umd-lib/k8s-avalon"
repository for server deployments.

Given these dependencies, a Git tag is typically created (with Docker images
created using that tag) whenever this repository undergoes a significant
changes (such as an Avalon version upgrade, or changes to the configuration of
UMD-customized Docker images) in order to provide stable versions of the Docker
images for use in local development and Kubernetes.

This means that the Git tag and Docker image creation does not usually occur in
sync with a QA/prod release, and, in fact, generally occurs much earlier in the
development lifecycle.

For example, the likely first step in an Avalon version upgrade would be to
incorporate the upstream "avalonmediasystem/avalon-docker" version changes into
this repository, before moving on to the version changes from the
"avalonmediasystem/avalon" repository (in the "umd-lib/avalon" codebase).
A Git tag, and the Docker images, should be created as soon as the
version update is complete in this repository, in order to provide stable Docker
versions for the changes in the "umd-lib/avalon" repository.

Similarly, if changes are needed to this repository as part of Avalon
development, those changes should be tagged as soon as reasonable (without
necessarily waiting for a QA/prod release) and the Docker images updated in the
"umd-lib/avalon" and "umd-lib/k8s-avalon" repositories.

This will likely result in some divergence between the "umd-lib/avalon" tags and
the tags in this repository. This is acceptable, since while the two
repositories are related, they have different lifecycles, which are reflected in
the Git tags.

## Git Tag Format

The tags used for the Docker images are built around two variable components --
the base Avalon version, and a UMD incrementing version for that
base version, having the form:

```text
<AVALON_VERSION>-umd-<INTEGER>
```

where

* \<AVALON_VERSION> - the Avalon version, i.e., `8.2`

  A three-part version number ("\<MAJOR>.\<MINOR>.\<PATCH>") is used,
  even if the corresponding Avalon tag has only two parts (i.e., a "7.8" version
  is assumed to be "7.8.0"). This provides greater consistency in the version
  numbers when the upstream Avalon does choose to use a minor version (such as
  "7.7.2" or "8.0.1").

* \<INTEGER> - an UMD incrementing version, i.e., `0`, `1`, etc.

Therefore the first Git tag based on an Avalon 8.2.0 release would be
`8.2.0-umd-0`, followed (if needed) by `8.2.0-umd-1`.

Note that the Git tags in the "umd-lib/avalon" repository follow the same
pattern, but that the Git tag (and subsequent Docker image tags) used by this
repository, and the tag used by the "umd-lib/avalon" repository (and its
Docker image) may differ. They will usually coincide in the Avalon version, but
could differ in the UMD incrementing version, as that is tracking each
repository's particular changes.

## Building the Docker Images

The following assumes that the repository has been tagged with \<GIT_TAG>,
which is then used as the version tag for the Docker images.

1. Create an environment variable with the Git tag:

   ```zsh
   export GIT_TAG=<GIT_TAG>
   ```

   For example, when building the Docker images for the first Avalon 8.2.0
   release, where the Git tag is "8.2.0-umd-0":

   ```zsh
   export GIT_TAG=8.2.0-umd-0
   ```

2. Checkout the tag:

   ```zsh
   git checkout $GIT_TAG
   ```

3. Build the HLS Nginx image:

    ```zsh
    cd nginx
    docker buildx build --no-cache . --builder kube --platform \
    linux/amd64,linux/arm64 --push -t docker.lib.umd.edu/nginx:avalon-$GIT_TAG
    cd ..
    ```

    The Docker image will be automatically pushed to the Nexus.

4. Build the Fedora (fcrepo) image:

    ```zsh
    cd fedora
    docker buildx build --no-cache . --builder kube --platform linux/amd64 \
      -f Dockerfile.fcrepo7-irsa-fix \
      --push -t docker.lib.umd.edu/fcrepo:7-avalon-$GIT_TAG
    cd ..
    ```

    The Docker image will be automatically pushed to the Nexus.

## UMD Customizations

### UMD-README.md

UMD-specific README.md describing use, procedures, and customizations.

### Nginx

The nginx configuration is based on the upstream
<https://github.com/avalonmediasystem/avalon-docker> `avalon-8.2` tag, with
UMD-specific additions (see below).

### nginx/Dockerfile

Updated to a multi-stage build using `phusion/baseimage:noble-1.0.2` (Ubuntu
24.04 Noble) as both builder and runtime base, replacing the previous
single-stage build on `phusion/baseimage:0.11` (Ubuntu 16.04 Xenial).

### nginx/nginx.conf.template

Added a second location block so that the streaming requests for S3-backed
derivatives are handled differently from the filesystem-backed derivatives. The
derivatives in S3 are handled using the PreSigned-URL provided by Avalon which
is UMD-customization since upstream uses Cloundfront for AWS deployment.

Also, modified to add "vod_segments_base_url" and "vod_base_url" to accommodate
the separate URLs needed streaming in Kubernetes, via the
`AVALON_STREAMING_BASE_URL` environment variable.

Added auth caching to reduce load on the auth service. The cache duration is
configurable via the `PROXY_CACHE_VALID_DURATION` environment variable
(default: 3m). The S3 presigned URL cache duration is configurable via the
`S3_PRESIGNED_URL_CACHE_DURATION` environment variable (default: 240 seconds).

Note that the `AVALON_STREAMING_BASE_URL` environment variable must also be
defined in the Docker Compose stack for the local development environment,
as it also uses this Docker image.

### nginx/build-nginx.sh

Updated to use `apt-get source nginx` (Ubuntu Noble system package) instead of
downloading a pinned tarball from nginx.org. Added the `--with-http_ssl_module`
and `--with-threads` flags for Kubernetes compatibility and VOD module async I/O.

### fedora/Dockerfile.fcrepo7-irsa-fix

Builds a custom `docker.lib.umd.edu/fcrepo` image on top of the stock
`fcrepo/fcrepo:7-tomcat10` image. It adds the AWS STS JAR that is missing from
the upstream Fedora distribution, which is required for
[IRSA (IAM Roles for Service Accounts)](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html)
/ web-identity token authentication against S3.

The fix detects the AWS SDK version already bundled in the Fedora webapp and
downloads the matching `sts` JAR from Maven Central — no manual version pinning
is required.

Upstream issues have been filed to add the AWS STS dependency directly to
Fedora and its dependencies, which would make this custom image unnecessary:

* <https://github.com/fcrepo/fcrepo/issues/2311> — fcrepo/fcrepo
* <https://github.com/OCFL/ocfl-java/issues/140> — OCFL/ocfl-java

Once either of those issues is resolved and the fix is included in a released
version of the upstream `fcrepo/fcrepo` image, this custom image can be
dropped in favor of the stock image.
