# IaC Scripts for Nightworkers Labs
Automatize infrastructure installation.

Ansible directory layout follows best practices (https://docs.ansible.com/ansible/2.8/user_guide/playbooks_best_practices.html#directory-layout).

## Pre-requisites (on Ubuntu Server)
https://docs.ansible.com/ansible/latest/installation_guide/installation_distros.html#installing-ansible-on-ubuntu

- Install Ansible (as Control Node)
  - `sudo apt update`
  - `sudo apt install -y software-properties-common`
  - `sudo add-apt-repository --yes --update ppa:ansible/ansible`
  - `sudo apt install -y ansible`

## How-To use (on server)
### Recommanded
Using VSCode is recommanded.
- Connect to remote server using `ms-vscode-remote.remote-ssh` extension. 
  - Configure any `.ssh/config` / `ssh_config` file with your server parameters set to it, with something like :
    ```
    Host whatever.hello.com
    HostName whatever.hello.com
    Port 1638
    User my_user
    ForwardAgent yes # Allows any local-machine Github credentials to be forwarded
    AddKeysToAgent yes # Allows any local-machine Github credentials to be forwarded
    UseKeychain yes # Allows any local-machine Github credentials to be forwarded
    IdentityFile  ~/.ssh/id_ed25519 # REQUIRED if wanting a passwordless connection, see below.
    ```
    - To get rid of passwords at connection, you might want to use SSH keys instead. To do so, on your local machine's terminal, run : 
        - `ssh-keygen`, Generate a brand new SSH private-public keypair. You'll need to copy the generated file's path to your `.ssh/config` / `ssh_config` `IdentityFile` parameters.
        - `ssh-copy-id -p <SSH_PORT> <user>@<domain>`, copies previously generated pubkey to `<user>`'s `.ssh/authorized_keys`, allowing connection without password.
    - You might want to use a custom `ssh_config` file stored on OneDrive / Google Drive. You'll need to configure `remote.SSH.configFile` extension parameter with the cloud stored file's path on your local machine for it to work (eg., `/Users/guillaumevara/Mon Drive/ssh/ssh_config`).

Make sure you are locally logged on `git` w/ a registered account using :
  - keychain-like features of your OS
  - having your local Github SSH keys agent-forwarded through `ms-vscode-remote.remote-ssh` as this documentation recommands, and obviously configured on your own GitHub account.

### Startup
- `git clone {this repo}`
- `ansible-galaxy install -r ansible/requirements.yml`
- `ansible-playbook -i ansible/inventories/production/hosts --become --become-user=root ansible/site.yml`

## Pre-requisites (on dev machine)
### On MacOS (Local Dev)
- `brew install ansible-lint`
### On Windows (Local Dev)
- #TODO
### On Linux - Ubuntu / Debian - (Remote Dev / SSH)
- #TODO