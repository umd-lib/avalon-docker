# bcm-avalon-docker

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
