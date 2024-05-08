# IaC Scripts for Nightworkers Labs
Automatize infrastructure installation for a single baremetal

## Pre-requisites (on Ubuntu Server)
https://docs.ansible.com/ansible/latest/installation_guide/installation_distros.html#installing-ansible-on-ubuntu

- Install Ansible (as Control Node)
  - `sudo apt update`
  - `sudo apt install -y software-properties-common`
  - `sudo add-apt-repository --yes --update ppa:ansible/ansible`
  - `sudo apt install -y ansible`

## How-To use (on server)
- `git clone {this repo}`
- `ansible-galaxy install -r requirements.yml`
- `ansible-playbook -i kubespray_config/hosts.ini --become --become-user=root all-playbook.yml`

## Pre-requisites (on dev machine)
### On MacOS
- `brew install ansible-lint`
### On Windows
- #TODO