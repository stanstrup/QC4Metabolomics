# Docker notes

```bash
docker build -t my_shinyapp .
docker build --no-cache -t my_shinyapp .

FOR /f "tokens=*" %i IN ('docker ps -q') DO docker stop %i
docker image prune -f & docker system prune

docker exec -it heuristic_bell bash

docker ps
docker kill dd999ddde1be

docker run -p 80:3838 my_shinyapp

docker-compose up --force-recreate --build
```





# Installation on RedHat server


## Install Docker
https://www.cyberciti.biz/faq/install-use-setup-docker-on-rhel7-centos7-linux/

```bash
sudo yum remove docker docker-common docker-selinux docker-engine-selinux && docker-engine docker-ce
sudo yum install -y yum-utils device-mapper-persistent-data lvm2
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install docker-ce
sudo systemctl enable docker.service
sudo systemctl start docker.service
```



## Install Docker compose

```bash
sudo yum install epel-release
sudo yum install -y python-pip
sudo pip install docker-compose
```



## Install QC4Metabolomics

Download QC4Metabolomics.

```bash
sudo yum install docker git git-lfs
cd /opt
sudo git lfs clone https://github.com/stanstrup/QC4Metabolomics.git
cd QC4Metabolomics/
sudo chmod +x ./setup/*.sh
```

Setup paths.


```bash
db_path=/var/lib/QC4Metabolomics/db
config_path=/var/lib/QC4Metabolomics/config
data_path=/var/lib/QC4Metabolomics/data
```


```bash
sudo mkdir -p $db_path
sudo mkdir -p $config_path
sudo mkdir -p $data_path
```

```bash
sudo sed -i "17s|^.*source.*$|        source: ${db_path}|g" docker-compose.yml
sudo sed -i "41s|^.*source.*$|          source: ${config_path}|g" docker-compose.yml
sudo sed -i "44s|^.*source.*$|          source: ${data_path}|g" docker-compose.yml
sudo sed -i "66s|^.*source.*$|          source: ${config_path}|g" docker-compose.yml
sudo sed -i "69s|^.*source.*$|          source: ${data_path}|g" docker-compose.yml
sudo sed -i "90s|^.*source.*$|          source: ${data_path}|g" docker-compose.yml
```



```R
sudo cp /opt/QC4Metabolomics/MetabolomiQCsR/inst/extdata/MetabolomiQCs.conf $config_path
```

Edit `$config_path/MetabolomiQCs.conf`



Build image and start. This can take hours.

```bash
sudo docker-compose up --force-recreate --build
```



Might not be needed.

```bash
systemctl enable firewalld
systemctl start firewalld

sudo firewall-cmd --add-port=80/tcp --permanent
sudo firewall-cmd --reload
sudo systemctl restart docker.service
```





# Update

```
sudo git fetch --all
sudo git reset --hard origin/master
```

redo from "sudo chmod +x ./setup/converter_cron.sh".



TODO: make script for the fixed and an update script.