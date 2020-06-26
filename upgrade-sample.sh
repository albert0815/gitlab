# before starting the update please check the background migrations:
docker exec -it gitlab bash
gitlab-rails console production

puts Sidekiq::Queue.new("background_migration").size
Sidekiq::ScheduledSet.new.select { |r| r.klass == 'BackgroundMigrationWorker' }.size

# if everything is fine, stop gitlab

docker stop gitlab && docker rm gitlab
docker stop gitlab-runner && docker rm gitlab-runner

# put in correct version in below docker images, make sure to go through the upgrade guide as per https://docs.gitlab.com/ee/policy/maintenance.html#upgrade-recommendations

docker run --detach \
    --publish 60722:22 \
    --publish 60780:60780 \
    --name gitlab \
    --restart always \
    --volume /docker-volumes/gitlab/config:/etc/gitlab \
    --volume /docker-volumes/gitlab/logs:/var/log/gitlab \
    --volume /docker-volumes/gitlab/data:/var/opt/gitlab \
    --volume /docker-volumes/backup:/backup\
    gitlab/gitlab-ce:11.11.8-ce.0

	
docker run -d --name gitlab-runner --restart always \
  -v /docker-volumes/gitlab-runner/config:/etc/gitlab-runner \
  -v /var/run/docker.sock:/var/run/docker.sock \
  gitlab/gitlab-runner:v11.11.4

  
docker network connect gitlab-network gitlab-runner || true
docker network connect gitlab-network gitlab || true

# now run the gitlab backup job in gitlab once

