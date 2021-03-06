#!/bin/bash
set -e
echo "starting installation of gitlab"

echo "removing old stuff"

backup_dir=/home/albert/windows-share/gitlab-backup

docker stop gitlab && docker rm gitlab
docker stop gitlab-runner && docker rm gitlab-runner

sudo rm -rf /docker-volumes/*
cp -a $backup_dir/docker-volumes/* /docker-volumes
ln -s $backup_dir /docker-volumes/backup

echo "starting gitlab docker image"
docker run --detach \
    --publish 60722:22 \
    --publish 60780:60780 \
    --name gitlab \
    --restart always \
    --volume /docker-volumes/gitlab/config:/etc/gitlab \
    --volume /docker-volumes/gitlab/logs:/var/log/gitlab \
    --volume /docker-volumes/gitlab/data:/var/opt/gitlab \
    --volume /docker-volumes/backup:/backup\
    gitlab/gitlab-ce:12.0.12-ce.0

echo "checking status of gitlab and waiting until it is healthy"
status=`docker inspect --format='{{.State.Health.Status}}' gitlab`
while [ "$status" != "healthy" ] 
do
	echo "status is $status, waiting another 5 secs"
	sleep 5
	status=`docker inspect --format='{{.State.Health.Status}}' gitlab`
done

echo "status is now $status, we will now restore the applications"

gitlab_backup_dir=/docker-volumes/backup/gitlab
backup_file=`ls -t $gitlab_backup_dir|head -1`
docker cp $gitlab_backup_dir/$backup_file gitlab:/var/opt/gitlab/backups
echo "using backup $gitlab_backup_dir$backup_file"

echo "stopping unicorn and sidekiq"
docker exec -it gitlab gitlab-ctl stop unicorn
docker exec -it gitlab gitlab-ctl stop sidekiq 

backup_version=`echo $backup_file|cut -c1-29`
echo "executing restore with version $backup_version"
docker exec -it gitlab gitlab-rake gitlab:backup:restore BACKUP=$backup_version
echo "executing starting gitlab"
docker exec -it gitlab gitlab-ctl start

#now we need to restore gitlab.rb and gitlab-secrets.json first and restart docker container gitlab

echo "starting runner image"
docker run -d --name gitlab-runner --restart always \
  -v /docker-volumes/gitlab-runner/config:/etc/gitlab-runner \
  -v /var/run/docker.sock:/var/run/docker.sock \
  gitlab/gitlab-runner:v12.0.2
 
echo "fixing rights of private keys"

chmod 600 /docker-volumes/gitlab/config/ssh_host_ecdsa_key /docker-volumes/gitlab/config/ssh_host_ed25519_key /docker-volumes/gitlab/config/ssh_host_rsa_key

echo "creating network for gitlab and gitlab runner"
docker network create --driver bridge gitlab-network || true

docker network connect gitlab-network gitlab-runner || true
docker network connect gitlab-network gitlab || true


echo "done, everything should work now" 
