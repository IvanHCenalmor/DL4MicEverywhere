# Brief overview of Docker desktop 

Docker containers and images can be managed from the Docker desktop application. It is particularly useful to see how many Docker images are installed in our computer and how many containers are actually running them.

## Clean Docker containers and images

Note that Docker images occupy in memory between 3 - 5 GB, so it is recommendable to check it from time to time and remove the unnecessary ones. For this, first check if there is any container using the image. If so, stop and remove it by clicking n the bin symbol. 

<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/DOCKER_DESKTOP_CONTAINER.png" 
     alt="Docker desktop container"
     width="50%" 
     height="50%" />


Then go to Images and remove the images that will not be used.

<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/DOCKER_DESKTOP_IMAGE.png" 
     alt="Docker desktop images"
     width="50%" 
     height="50%" />

To list all the container images that currently occupy space on your computer:

`sudo docker images`

to clear all unused images:

`docker image prune -a`

to clear all unused containers, networks, images:

`docker system prune -a`


## Pause, restart or kill Docker

To pause, restart or close Docker you can always click on the shortcut symbol of docker: 
<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/STOP_DOCKER.png" 
     alt="Docker desktop images"
     width="50%" 
     height="50%" />