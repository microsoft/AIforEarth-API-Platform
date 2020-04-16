# AI for Earth API Platform Image
The AI for Earth API Platform Dockerfile copies the libraries required to provide distributed functionality within the API Platform.  This image is to be used in conjunction with an image derived from an official AI for Earth image ([python](https://hub.docker.com/_/microsoft-aiforearth-base-py) or [R](https://hub.docker.com/_/microsoft-aiforearth-base-r)). 

## How to use
The Dockerfile is simple to use with one of your previously created images.  Simply build a new image based on this GitHub directory:
```
docker build https://github.com/microsoft/AIforEarth-API-Platform.git:Containers --build-arg SERVICE_IMAGE_BASE=<your_image> [--build-arg LANGUAGE=py|r]
```
For example, if you were to build a production-ready image off of the AI for Earth Python image, you would do so like this:
```
docker build https://github.com/microsoft/AIforEarth-API-Platform.git:Containers --build-arg SERVICE_IMAGE_BASE=mcr.microsoft.com/aiforearth/base-py:latest
```
Likewise, if you wanted to use the AI for Earth R image, you would do so like this (but with an additonal language specification):
```
docker build https://github.com/microsoft/AIforEarth-API-Platform.git#:Containers --build-arg SERVICE_IMAGE_BASE=mcr.microsoft.com/aiforearth/base-r:latest --build-arg LANGUAGE=r
```