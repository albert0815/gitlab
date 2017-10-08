#!/bin/bash

echo "starting installation of gitlab"

if [ "$#" -ne 1 ]; then
    echo "required parameter: path to tar file of backup"
fi

backup_name=$1

docker_installation_dir=/Users/albert/docker

mkdir $docker_installation_dir
#create volume directory
mkdir $docker_installation_dir/docker-volumes
su ln -s $docker_installation_dir/docker-volumes /docker-volumes



docker-compose up

docker exec -it gitlab_web_1 gitlab-ctl stop unicorn
docker exec -it gitlab_web_1 gitlab-ctl stop sidekiq 

docker exec -it gitlab_web_1 gitlab-rake gitlab:backup:restore BACKUP=`$backup_name|cut -c1-28`
docker exec -it gitlab_web_1 gitlab-ctl start
