import requests as r
import json, time, paramiko
from os.path import abspath

# params
project = "f6e4fedb-bc42-40ac-8eb5-6e2a6245ed6c" # just a random GUID for example, not live
droplet_name = "example.com"
ssh_private_key = abspath(".ssh/id_rsa")
APIKey = 'Bearer API_KEY_HERE'

# basic header setup
Headers = { "Content-Type": "application/json", "Authorization": APIKey }

# grab the SSH keys to use
print "[*]  Grabbing the SSH keys"
ssh_keys = []
ssh_key_response = r.get('https://api.digitalocean.com/v2/account/keys', headers=Headers)
for sk in ssh_key_response.json()['ssh_keys']:
    ssh_keys.append(sk['id'])

# from the request - creates an 18.04 LTS LEMP BOX (image id: 38799526)
Request = {
           "name": droplet_name,
           "region": "lon1",
           "size": "s-1vcpu-1gb",
           "image": "38799526",
           "ssh_keys": ssh_keys,
           "backups": False,
           "ipv6": False,
           "user_data": None,
           "private_networking": False,
           "volumes": None,
           "tags": ["WordPress"]
          }

# create the droplet
print "[*]  Creating the droplet 'LEMP Ubuntu 18.04 LTS'"
create_response = r.post('https://api.digitalocean.com/v2/droplets', json=Request, headers=Headers)
droplet_id = create_response.json()["droplet"]["id"]
print "[*]  Droplet created with ID {}".format(droplet_id)
time.sleep(2)

# Move droplet to project
print "[*]  Assigning the droplet to project {}".format(project)
Request = {
           "resources": ['do:droplet:{}'.format(droplet_id)]
          }
response = r.post('https://api.digitalocean.com/v2/projects/{}/resources'.format(project), headers=Headers, json=Request)

# wait for droplet to build
while True:

    res = r.get('https://api.digitalocean.com/v2/droplets/{}'.format(droplet_id), headers=Headers)
    status = res.json()["droplet"]["status"]
    droplet_info = res.json()["droplet"]

    # grab the IP address of the public interface
    for net in droplet_info["networks"]["v4"]:
        if net['type'] == "public":
            droplet_ip = net['ip_address']
            break

    if status == "active":
        break

    print "[*]  Waiting for droplet {} to finish building".format(droplet_name)
    time.sleep(45)

# droplet finished building
print "[*]  Droplet has been created: public IP is {}".format(droplet_ip)

# create SSH object and accept host key
DropletSSH = paramiko.SSHClient()
DropletSSH.set_missing_host_key_policy(paramiko.AutoAddPolicy())

# connect
print "[*]  Now configuring WordPress, attempting to SSH into the droplet"
time.sleep(10) # pause for 10 seconds to let the droplet boot
DropletSSH.connect(droplet_ip, username="root", key_filename=ssh_private_key)

# download wordpress ready for use
commands = "wget https://wordpress.org/latest.tar.gz\n"
commands += "rm -rf /var/www/html\n"
commands += "tar xzf latest.tar.gz\n"
commands += "mv ./wordpress /var/www/html\n"
commands += "chmod www-data:www-data -R /var/www/html\n"
stdin, stdout, stderr = DropletSSH.exec_command(commands)
print stdout.read()

# todo: configure wordpress and create database
print "[*]  WordPress installed ok"

# logout
DropletSSH.close()
