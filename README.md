See [BCM-README.md](./BCM-README.md)

# avalon-docker
The project contains the Dockerfiles for all the necessary components of [Avalon Media System](http://github.com/avalonmediasystem/avalon)

## Usage
1. Clone this Repo and checkout the desired branch
2. Copy dotenv.example to .env and fill in the passwords and Rails secrect key base.

### On Linux
1. Install [Docker](https://docs.docker.com/engine/installation/linux/centos/)
2. Install [Docker-Compose](https://docs.docker.com/compose/install/)
3. From inside the avalon-docker directory
  * `docker-compose pull` to get the prebuilt images from [Dockerhub](dockerhub.com)
  * `docker-compose up` to stand up the stack

### On a Mac
* Install [Docker Toolbox for OS X](https://www.docker.com/products/docker-toolbox)
* Run
  * `docker-machine stop default`
  * `docker-machine start default`
  * `docker-machine env`
  * `eval $(docker-machine env)`
  * `docker-machine start default`
  * `docker-compose up`
* The docker container will be accessible via `http://192.168.99.100:8888/`
* if anytime OS X says docker is not started, rerun `eval $(docker-machine env)

### Notes
* `docker-compose logs <service_name>` to see the container(s) logs
* `docker-compose build --no-cache <service_name>` to build the image(s) from scratch
* `docker ps` to see all running containers
* `docker exec -it avalondocker_avalon_1 /bin/bash` to get into the Avalon docker container

### Developing for Avalon using Docker
1. Checkout [avalon](http://github.com/avalonmediasystem/avalon) next to the avalon-docker directory
2. Copy config files to Avalon `cp avalon-docker/avalon/config/* avalon/config/`
3. Add postgres gem: `echo "gem 'pg'" > avalon/Gemfile.local`
4. In avalon-docker,`cp dotenv.example .env` and fill out this file
5. Get the images from Dockerhub: `docker-compose -f docker-compose-dev.yml pull`
6. Bring up the stack: `docker-compose -f docker-compose-dev.yml up`
7. After the Avalon container is fully up, it will pick up changes in the avalon directory
