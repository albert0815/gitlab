#!/bin/bash
set -e
echo "starting installation of gitlab"

echo "removing old stuff"

backup_dir=/Volumes/FRITZ.NAS/PI-239-USB2-0Drive-01/gitlab-backup


rm -rf /docker-volumes/*
cp -rf $backup_dir/docker-volumes/* /docker-volumes
ln -s $backup_dir /docker-volumes/backup
docker stop gitlab && docker rm gitlab


echo "starting gitlab docker image"
docker run --detach \
    --hostname alberts-mini.fritz.box \
    --env GITLAB_OMNIBUS_CONFIG="external_url 'http://alberts-mini.fritz.box:60700'; gitlab_rails['gitlab_shell_ssh_port'] = 60722" \
    --publish 60700:60700 --publish 60722:22 \
    --name gitlab \
    --restart always \
    --volume /docker-volumes/gitlab/config:/etc/gitlab \
    --volume /docker-volumes/gitlab/logs:/var/log/gitlab \
    --volume /docker-volumes/gitlab/data:/var/opt/gitlab \
    --volume /docker-volumes/backup:/backup\
    gitlab/gitlab-ce:10.0.3-ce.0

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
cp $gitlab_backup_dir/$backup_file /docker-volumes/gitlab/data/backups
echo "using backup $gitlab_backup_dir$backup_file"

echo "stopping unicorn and sidekiq"
docker exec -it gitlab gitlab-ctl stop unicorn
docker exec -it gitlab gitlab-ctl stop sidekiq 

backup_version=`echo $backup_file|cut -c1-28`
echo "executing restore with version $backup_version"
docker exec -it gitlab gitlab-rake gitlab:backup:restore BACKUP=$backup_version
echo "executing starting gitlab"
docker exec -it gitlab gitlab-ctl start

echo "starting runner image"
docker run -d --name gitlab-runner --restart always \
  -v /docker-volumes/gitlab-runner/config:/etc/gitlab-runner \
  -v /var/run/docker.sock:/var/run/docker.sock \
  gitlab/gitlab-runner:v10.0.2
  
echo "you need to register the runner now: docker exec -it gitlab-runner gitlab-runner register. after registration you need to change volumes config of the runner."
