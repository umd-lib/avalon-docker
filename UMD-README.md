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

* Customized Avalon Docker images
* Stock Avalon Docker images that have been tagged with a specific version.
  This is needed because some Avalon Docker images use images without tags, or
  with non-stable tags (such as "postgres:14-alpine), and SSDR policy is to only
  use Docker images with specific tags in the server environment.
* Docker images not provided by Avalon

All Docker images should be built using "docker buildx" and the Kubernetes
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

* \<AVALON_VERSION> - the Avalon version, i.e., `7.8.0`

  A three-part version number ("\<MAJOR>.\<MINOR>.\<PATCH>") is used,
  even if the corresponding Avalon tag has only two parts (i.e., a "7.8" version
  is assumed to be "7.8.0"). This provides greater consistency in the version
  numbers when the upstream Avalon does choose to use a minor version (such as
  "7.7.2" or "8.0.1").

* \<INTEGER> - an UMD incrementing version, i.e., `0`, `1`, etc.

Therefore the first Git tag based on an Avalon 7.8 release would be
`7.8.0-umd-0`, followed (if needed) by `7.8.0-umd-1`.

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

   For example, when building the Docker images for the first Avalon 7.8
   release, where the Git tag is "7.8.0-umd-0":

   ```zsh
   export GIT_TAG=7.8.0-umd-0
   ```

2. Checkout the tag:

   ```zsh
   git checkout $GIT_TAG
   ```

3. Create environment variables for each of the stock Docker images being
   renamed and redeployed to the Nexus.

   The following commands use the "[yq](https://github.com/mikefarah/yq)"
   utility to parse the Docker image names from the "docker-compose.yml" file:

    ```zsh
    export DB_IMAGE=`yq '.services.db.image' docker-compose.yml`
    export FEDORA_IMAGE=`yq '.services.fedora.image' docker-compose.yml`
    export SOLR_IMAGE=`yq '.services.solr.image' docker-compose.yml`
    export REDIS_IMAGE=`yq '.services.redis.image' docker-compose.yml`
    ```

4. Pull the Docker images, specifying the "linux/amd64" architecture used by
   Kubernetes. (Cannot use "docker-compose pull", because on an Apple Silicon
   Mac, the "arm64" Docker images will be retrieved).

   ```zsh
   docker pull --platform=linux/amd64 $DB_IMAGE
   docker pull --platform=linux/amd64 $FEDORA_IMAGE
   docker pull --platform=linux/amd64 $SOLR_IMAGE
   docker pull --platform=linux/amd64 $REDIS_IMAGE
   ```

5. Tag the images with a UMD-specific version number:

    ```zsh
    docker tag $DB_IMAGE docker.lib.umd.edu/db:fedora4-avalon-$GIT_TAG
    docker tag $FEDORA_IMAGE docker.lib.umd.edu/fedora:4.7.5-avalon-$GIT_TAG
    docker tag $SOLR_IMAGE docker.lib.umd.edu/solr:avalon-$GIT_TAG
    docker tag $REDIS_IMAGE docker.lib.umd.edu/redis:avalon-$GIT_TAG
    ```

    ----

    **Note:** Prior to Avalon 7.8, these stock Docker images were typically
    tagged only with the Avalon version number (i.e., "7.5.1").

    ----

6. Push the images to the UMD Nexus:

    ```zsh
    docker push docker.lib.umd.edu/db:fedora4-avalon-$GIT_TAG
    docker push docker.lib.umd.edu/fedora:4.7.5-avalon-$GIT_TAG
    docker push docker.lib.umd.edu/solr:avalon-$GIT_TAG
    docker push docker.lib.umd.edu/redis:avalon-$GIT_TAG
    ```

7. Build the HLS Nginx image:

    ```zsh
    cd nginx
    docker buildx build --no-cache . --builder kube --platform linux/amd64 \
      --push -t docker.lib.umd.edu/nginx:avalon-$GIT_TAG
    cd ..
    ```

    The Docker image will be automatically pushed to the Nexus.

8. Build the SFTP (with rsync) image:

    ```zsh
    cd sftp
    docker buildx build --no-cache . --builder kube --platform linux/amd64 \
      --push -t docker.lib.umd.edu/avalon-sftp:GIT_TAG
    cd ..
    ```

    The Docker image will be automatically pushed to the Nexus.

## UMD Customizations

### UMD-README.md

UMD-specific README.md describing use, procedures, and customizations.

### SFTP Docker configuration

The SFTP Docker configuration (in the "sftp" subdirectory) is a UMD addition to
this repository, used to support SFTP uploads to Avalon.

### Nginx

### nginx/nginx.conf.template

Modified to add "vod_segments_base_url" and "vod_base_url" to accommodate
the separate URLs needed streaming in Kubernetes, via the
`AVALON_STREAMING_BASE_URL` environment variable.

Note that the `AVALON_STREAMING_BASE_URL` environment variable must also be
defined in the Docker Compose stack for the local development environment,
as it also uses this Docker image.

### nginx/build-nginx.sh

Added the "--with-http_ssl_module" for use with Kubernetes.
