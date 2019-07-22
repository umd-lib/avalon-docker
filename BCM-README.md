# bcm-avalon-docker

### Developing for Broadcast Avalon using Docker

1. Checkout [avalon](https://github.com/umd-lib/avalon) next to the avalon-docker directory.
    In avalon, change the config/setting.yml redis settings to:

    ```
    redis:
      host: redis 
      port: 6379
    ```

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


### Creating BCM Docker Images for AWS

Avalon uses some of the native AWS services in place of services such as Redis, 
Postgres, etc. Therefore, the Docker image needs to build with the necessary AWS
gems. Also, the entrypoint script should behave differently in the AWS environment.
This can be achieved by setting specific environment variables in your `.env` file
before building the image.

1. Ensure necessary env variables are set.

    ```
    BUNDLE_WITH=aws
    TAG_SUFFIX=-bcm-0
    
    # For SNAPSHOT builds to be pushed to Nexus
    SNAPSHOT_SUFFIX=-SNAPSHOT_
    AVALON_COMMIT=e7a5536
    ```

    For test running a AWS Image based container locally,
    ```
    SETTINGS__ACTIVE_JOB__QUEUE_ADAPTER=better_active_elastic_job
    RAILS_GROUPS=aws
    ```

2. Build the image

    ```
    docker-compose build --no-cache avalon
    
    ```

3. Test the Avalon application container 

    ```
    docker-compose up
    ```

4. Verify that the BCM App is up at http://localhost
   
   The application may not work correctly because of missing AWS service dependencies.

5. Push the image to UMD Nexus Docker registry.
   
   ```
   docker-compose push <image-name-with-tag-build-on-step-2>
   ```
