# bcm-avalon-docker

### Developing for Broadcast Avalon using Docker
1. Checkout [avalon](http://github.com/avalonmediasystem/avalon) next to the avalon-docker directory
2. Copy config files to Avalon `cp avalon-docker/avalon/config/* avalon/config/`
3. In avalon-docker,`cp dotenv.example .env` and fill out this file
4. Get the images from Dockerhub: `docker-compose -f docker-compose-dev.yml pull`
5. Bring up the stack: `docker-compose -f docker-compose-dev.yml up`
6. After the Avalon container is fully up, it will pick up changes in the avalon directory
7. `docker exec -it avalondocker_avalon_1 /bin/bash` to get into the Avalon docker container

Example values for `.env` required settings
```
# Required Settings
APP_NAME=avalon
BASE_URL=http://localhost:3000/
STREAMING_HOST=localhost
AVALON_DB_PASSWORD=avalon
FEDORA_DB_PASSWORD=fedora
SECRET_KEY_BASE=cd19c21931892c5ab2bf630f51dcb96ec8c869029123ce91614f2d1708b95410d4d58f4b9d4fcef0ea37e386ad56e9259dc7258818a7a71c65b2037561be30c8
AVALON_BRANCH=bcm-docker
```