# Avalon Pilot

Instructions to build and deploy Avalon Pilot docker images to the UMD Nexus Docker Registry.

## Build and push images to UMD Nexus Docker Registry
```
docker-compose -f avalon-pilot-compose.yml build db fedora avalon
docker-compose -f avalon-pilot-compose.yml push db fedora avalon
```
Note: Currently, db, fedora, and avalon are the only customized images. If other images are customized, those needs to be included in the above commands to be built and pushed to the UMD Nexus Docker Registry.


## Pull and push images to UMD Nexus Docker Registry
For images that does not need any customization, we can pull (from dockerhub), tag, and push (to UMD Docker). The avalon docker images for supporting services does seem to follow a consistent pattern for versioning, so we can tag them with the Avalon application version they are compatible with.

```
docker pull avalonmediasystem/<service>:<tag>
docker tag avalonmediasystem/<service>:<tag> docker.lib.umd.edu/avalonmediasystem/<service>:<avalon-app-version>
docker push docker.lib.umd.edu/avalonmediasystem/<service>:<avalon-app-version>
```

**Note:** After pulling the image, we need to verify that the images are compatible with the Avalon application before tagging and pushing.

Example: Pulling the current avalonmediasystem images and tagging them as 6.4.2 compatible images.
```
docker pull avalonmediasystem/solr:latest
docker pull avalonmediasystem/matterhorn
docker pull avalonmediasystem/nginx

docker tag avalonmediasystem/solr:latest docker.lib.umd.edu/avalonmediasystem/solr:6.4.2
docker tag avalonmediasystem/matterhorn docker.lib.umd.edu/avalonmediasystem/matterhorn:6.4.2
docker tag avalonmediasystem/nginx docker.lib.umd.edu/avalonmediasystem/nginx:6.4.2

docker push docker.lib.umd.edu/avalonmediasystem/solr:6.4.2
docker push docker.lib.umd.edu/avalonmediasystem/matterhorn:6.4.2
docker push docker.lib.umd.edu/avalonmediasystem/nginx:6.4.2
```