# UMD Avalon

## About the Docker images

Both the UMD Avalon local development environment and Kubernetes stack use
images built from this repository.

The UMD Avalon stack consists of

* Customized Avalon Docker images
* Stock Avalon Docker images that have been tagged with a specific version.
  This is needed because some Avalon Docker images use images without tags, or
  with non-stable tags (such as "latest), and SSDR policy is to only use
  Docker images with specific tags in the server environment.
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

## UMD-customized Docker Images

The tags used for the UMD-customized Docker images are built around two variable
components, the base Avalon version, and an UMD incrementing version for that
base version.

These Docker images are typically tagged just prior to promoting Avalon to
Kubernetes for a release.

See the "Stock Avalon Docker images" section for information on
tagging Avalon-provided images that are not customized, and are typically
tagged at the beginning of an Avalon upgrade.

To simplify the instructions below, the following two environment variables
are used in specifying the Docker tags:

* AVALON_VERSION - the Avalon version, i.e., `7.6`
* UMD_VERSION - combination of the Avalon version, and UMD incrementing
                version, i.e., `7.6-umd-0`

For example, to create the environment variables for generating the Docker tags
for the first UMD version based on Avalon 7.6:

```zsh
export AVALON_VERSION=7.6
export UMD_VERSION=$AVALON_VERSION-umd-0
```

### Building the UMD-customized Docker images

#### HLS Nginx

To build the HLS Nginx image

```zsh
cd nginx
docker buildx build --no-cache . --builder kube --platform linux/amd64 --push -t docker.lib.umd.edu/nginx:avalon-$UMD_VERSION
```

The Docker image will be automatically pushed to the Nexus.

#### SFTP

To build the SFTP (with rsync) image

```zsh
cd sftp
docker buildx build --no-cache . --builder kube --platform linux/amd64 --push -t docker.lib.umd.edu/avalon-sftp:$UMD_VERSION
```

The Docker image will be automatically pushed to the Nexus.

#### Avalon

The main Avalon image is built using the Dockerfile in the
<https://github.com/umd-lib/avalon> project.

## Stock Avalon Docker images

**Note:** When tagging these images, the "amd64" architecture images must be
used, as that is the architecture expected by Kubernetes.

To tag and deploy stock images to Nexus

1. Checkout the *Avalon* tag for the release (i.e., "avalon-7.6.0"), to ensure
   that a tagged commit of the repository is used. Using an Avalon-provided
   tag, instead of a UMD custom tag because these images are typically created
   at the start of an Avalon version upgrade, and no UMD tags for the version
   exist.

   ```zsh
   git checkout <AVALON_TAG>
   ```

   where \<AVALON_TAG> is the Avalon version for the release.

2. Create environment variables for each of the stock Docker images being
   renamed and redeployed to the Nexus.

   The following commands use the "[yq](https://github.com/mikefarah/yq)"
   utility to parse the Docker image names from the "docker-compose.yml" file:

    ```zsh
    export DB_IMAGE=`yq '.services.db.image' docker-compose.yml`
    export FEDORA_IMAGE=`yq '.services.fedora.image' docker-compose.yml`
    export SOLR_IMAGE=`yq '.services.solr.image' docker-compose.yml`
    export REDIS_IMAGE=`yq '.services.redis.image' docker-compose.yml`
    ```

3. Pull the Docker images, specifying the "linux/amd64" architecture used by
   Kubernetes. (Cannot use "docker-compose pull", because on an Apple Silicon
   Mac, the "arm64" Docker images will be retrieved).

   ```zsh
   docker pull --platform=linux/amd64 $DB_IMAGE
   docker pull --platform=linux/amd64 $FEDORA_IMAGE
   docker pull --platform=linux/amd64 $SOLR_IMAGE
   docker pull --platform=linux/amd64 $REDIS_IMAGE
   ```

4. Tag the images with a UMD-specific version number:

    ```zsh
    docker tag $DB_IMAGE docker.lib.umd.edu/db:fedora4-avalon-$AVALON_VERSION
    docker tag $FEDORA_IMAGE docker.lib.umd.edu/fedora:4.7.5-avalon-$AVALON_VERSION
    docker tag $SOLR_IMAGE docker.lib.umd.edu/solr:avalon-$AVALON_VERSION
    docker tag $REDIS_IMAGE docker.lib.umd.edu/redis:avalon-$AVALON_VERSION
    ```

5. Push the images to the UMD Nexus:

    ```zsh
    docker push docker.lib.umd.edu/db:fedora4-avalon-$AVALON_VERSION
    docker push docker.lib.umd.edu/fedora:4.7.5-avalon-$AVALON_VERSION
    docker push docker.lib.umd.edu/solr:avalon-$AVALON_VERSION
    docker push docker.lib.umd.edu/redis:avalon-$AVALON_VERSION
    ```

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
