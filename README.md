# How to restore gitlab

Restore docker-volume directory from backup in /docker-volumes. E.g.:

Create directories:
```bash
docker_installation_dir=/Users/albert/docker
mkdir $docker_installation_dir
mkdir $docker_installation_dir/docker-volumes
su ln -s $docker_installation_dir/docker-volumes /docker-volumes
```

Now populate /docker-volumes with all the relevant files from the backup (we don't need gitlab dir).

Afterwards we can use the setup-gitlab.sh script to restore gitlab from the backup.

```bash
git clone git@github.com:albert0815/gitlab.git
cd gitlab
./setup-gitlab.sh
```

as a last step the runner is started. after startup you need to change the config of the runner in /docker-volumes/gitlab-runner/config/config.toml
```
volumes = ["/Volumes/FRITZ.NAS/PI-239-USB2-0Drive-01/gitlab-backup:/backup", "/var/run/docker.sock:/var/run/docker.sock", "/cache"]
```

now you should be able to deploy images with gitlab
