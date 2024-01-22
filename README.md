# Hadoop pseudo distributed mode dockerized
Flexible Hadoop Docker image to aid local development. Forked and modified to add Spark.

## Quick start
Start the container using:
```
docker-compose up -d
```

## Usage
Attach and interact with the container by running `docker-compose exec hadoop bash` or `docker run -it <container id>`.

## Web interfaces
* Namenode <http://localhost:9870>  
* Secondary namenode <http://localhost:9868>  
* Datanode <http://localhost:9864>  
* Resource manager <http://localhost:8088>  
* Node manager <http://localhost:8042>
* Spark <http://localhost:4040>

## Configuration
The image only uses default configuration. Customization can be done by modifying the files inside the Hadoop configurations folder.  