#!/bin/bash

echo "starting installation of gitlab"

echo "starting gitlab docker image"
docker run --detach \
    --hostname alberts-mini.fritz.box \
    --env GITLAB_OMNIBUS_CONFIG="external_url 'http://http://alberts-mini.fritz.box:60700'; gitlab_rails['gitlab_shell_ssh_port'] = 60722" \
    --publish 60700:60700 --publish 60722:22 \
    --name gitlab \
    --restart always \
    --volume /docker-volumes/gitlab/config:/etc/gitlab \
    --volume /docker-volumes/gitlab/logs:/var/log/gitlab \
    --volume /docker-volumes/gitlab/data:/var/opt/gitlab \
    --volume /docker-volumes/backup:/backup\
    gitlab/gitlab-ce:10.0.3

git clone https://github.com/vishnubob/wait-for-it
wait-for-it/wait-for-it.sh localhost:60700

backup_dir=/docker-volumes/backup/gitlab/applications
backup_file=`ls -t backup_dir|head -1`
echo "using backup $backup_dir$backup_file"
cp $backup_dir$backup_file /docker-volumes/gitlab/data/data/backups

echo "stopping unicorn and sidekiq"
docker exec -it gitlab_web_1 gitlab-ctl stop unicorn
docker exec -it gitlab_web_1 gitlab-ctl stop sidekiq 

echo "executing restore"
docker exec -it gitlab_web_1 gitlab-rake gitlab:backup:restore BACKUP=`$backup_file|cut -c1-28`
echo "executing starting gitlab"
docker exec -it gitlab_web_1 gitlab-ctl start

echo "starting runner image"
docker run -d --name gitlab-runner --restart always \
  -v /docker-volumes/gitlab-runner/config:/etc/gitlab-runner \
  -v /var/run/docker.sock:/var/run/docker.sock \
  gitlab/gitlab-runner:10.0.2
  
echo "you need to register the runner now: docker exec -it gitlab-runner gitlab-runner register. after registration you need to change volumes config of the runner."