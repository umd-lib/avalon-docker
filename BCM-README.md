# bcm-avalon-docker

### Developing for Broadcast Avalon using Docker

1. Checkout [avalon](https://github.com/umd-lib/avalon) next to the avalon-docker directory.

2. Copy config files from avalon-docker to avalon:

    ```
    cp avalon-docker/avalon/config/* avalon/config/
    ```
    
3. Copy the `controlled_vocabulary.yml.example` file to `controlled_vocabulary.yml`
 
    ```
    cp avalon/config/controlled_vocabulary.yml.example avalon/config/controlled_vocabulary.yml
    ```

4. In avalon-docker, copy the `dotenv.example` file to `.env`:

    ```
    cd avalon-docker
    cp dotenv.example .env
    ```
    
    and fill out the entries in the file.

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
    
    **Note:** Some lines may need to be added.

5. Get the images from Dockerhub:
    
    ```
    docker-compose -f docker-compose-dev.yml pull
    ```
    
6. Ensure that these directories are configured to be mountable by Docker containers:
    * avalon
    * avalon-docker/gems
    * avalon-docker/masterfiles

    **Docker Community Edition of Mac OS X:** Click the Docker icon in the system
    menubar, select *Preferences...* then *File Sharing*. Add the full paths to the
    directories listed above, then click *Apply & Restart*.

7. Bring up the stack:

    ```
    docker-compose -f docker-compose-dev.yml up
    ```
    
8. After the Avalon container is fully up, it will pick up changes in the avalon directory

9. Access the shell in the Avalon docker container:

    ```
    docker exec -it avalon-docker_avalon_1 /bin/bash
    ```