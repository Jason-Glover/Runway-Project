## Image Manager containerized

While having docker on your machine running execute `./setup.sh`. This will check out the application to your local machine and build the docker image.

Validate that the container is working by running it using:

```
docker run -dp 5000:5000 img-mgr
```

Open your web browser to `http://localhost:5000`. It doesn't have permissions to upload the files to S3, that is to be expected.

You can kill the container by finding the container id `docker ps`. Once the container ID is known use that to `docker kill CONTAINER_ID` where CONTAINER_ID is the one printed out from `docker ps`.

### ECR

Within the AWS web console create an Elastic Container Registry. The name of the registry can be that of the application, so we'll name it `img-mgr`. All of the other values can be taken as default for this private repo.

Find the "Push commands" for your repo. This will provide guidance on how to get your local image pushed up to this repo. You can skip step 2 in this process because we've already built the image on our machine.
