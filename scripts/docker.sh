# https://docs.docker.com/engine/install/linux-postinstall/

# Create the docker group.
sudo groupadd docker

# Add your user to the docker group.activate the changes to groups
sudo usermod -aG docker $USER

# activate the changes to groups
newgrp docker 
