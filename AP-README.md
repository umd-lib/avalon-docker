# Avalon Pilot

Instructions to build and deploy Avalon Pilot docker images to the UMD Nexus Docker Registry.

## Build and push images to UMD Nexus Docker Registry
```
docker-compose -f avalon-pilot-compose.yml build db fedora avalon
docker-compose -f avalon-pilot-compose.yml push db fedora avalon
```
Note: Currently, db, fedora, and avalon are the only customized images. If other images are customized, those needs to be included in the above commands to be built and pushed to the UMD Nexus Docker Registry.