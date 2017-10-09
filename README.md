# Prereq mac
install brew
```bash
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
brew install coreutils
PATH="/usr/local/opt/coreutils/libexec/gnubin:$PATH"
```

# How to restore gitlab

Create place where the docker stuff will be available. E.g.:

Create directories:
```bash
docker_installation_dir=/Users/albert/docker
mkdir $docker_installation_dir
mkdir $docker_installation_dir/docker-volumes
su ln -s $docker_installation_dir/docker-volumes /docker-volumes
```

You need to add this dir in the configuration of docker to be allowed for sharing 
(see e.g. https://stackoverflow.com/questions/45122459/docker-mounts-denied-the-paths-are-not-shared-from-os-x-and-are-not-known).

Afterwards we can use the setup-gitlab.sh script to restore gitlab from the backup (in case backup is in a different folder than expected
you need to change it in the script as this script restores the docker-volumes directory backup).

```bash
git clone git@github.com:albert0815/gitlab.git
cd gitlab
./setup-gitlab.sh
```

now you should be able to deploy images with gitlab

# Certbot
certbot certonly --webroot -w /usr/share/nginx/letsencrypt -d www.dirkpapenberg.de