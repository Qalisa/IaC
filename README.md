# IaC (Infrastructure as Code)
Automatize the installation of an opinionated infrastructure for your organization.
Ansible directory layout follows best practices (https://docs.ansible.com/ansible/2.8/user_guide/playbooks_best_practices.html#directory-layout).

## How-To use (on server)

### Requirements and considerations
IaC must be installed on an Ubuntu / Debian system. Has been tested only on-site with a SSH session, not remotely using ansible host.

#### About SMTP Trafic and SMTP providers (Outlook, Gmail...) network trust checks
Use https://www.mail-tester.com/, https://www.helloinbox.email/ or https://mxtoolbox.com/emailhealth to test trustness of IaC mail installation.
- Some Server Providers / ISPs disable SMTP outbound trafic, preventing from sending mail. Please act accordingly to enable it.
  - Scaleway: https://www.scaleway.com/en/docs/elastic-metal/how-to/enable-smtp/
- Some providers might require (rDNS) or PTR to match to route SMTP trafic from this server. Make it so it matches the mail.<root_domain> domain name.
  - https://mxtoolbox.com/ReverseLookup.aspx to test correctness
  - Scaleway: https://www.scaleway.com/en/docs/elastic-metal/how-to/configure-reverse-dns-flexible-ip/
- postmaster tools:
  - https://postmaster.google.com/managedomains?pli=1
  - https://sendersupport.olc.protection.outlook.com/snds/index.aspx

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
- (Optional) Login with SSH as `root` on your future master node (node1)
  - or, same user (with root privileges) as defined in `ansible/inventories/production/hosts.yaml`. If users differ, you might experiment strange behavior from ansible / python invocations.
- `git clone {this repo}`
- Launch VSCode Task `⛏1. Install Ansible & tools`
- Launch VSCode Task `⛏2a. Install IaC requirements`
- (Optional) If working remotely on the node master, reboot the server so `ansible-lint` will be acknoledged
- Create a `./.ansible-vault-pw` file, containing a password to secure all the secrets related to this stack within ansible vault technology
- Configure:
  - As documented in `./ansible/inventories/group_vars/all/vars`, create `./ansible/inventories/group_vars/all/vault` file, and fill accordingly
  - Customize `./ansible/inventories/production/group_vars/all/01-IaC.yml` as needed
  - (Optional) Encrypt `./ansible/inventories/group_vars/all/vault` using VSCode Task `🔒 Ansible Vault: Encrypt`
- (Optional) You might want to opt-out of certain services by commenting roles within `./ansible/playbooks/site.yml`
- Launch VSCode Tasks `🚀 Install: K3s`, then `🚀 Install: Services`

## Overlook of available services
Once cluster is setup, you can review all availables services through `book.<root_domain>`.

## Create new users (LDAP / mail)
By default, only 2 users are created: `postmaster` and `donotreply`, which are required. If you want to create more:
- Use LAM service (`https://admin-ldap.<root_domain>`), and login as admin.
- Create a new user in `ou=<domain>,cn=email-users,dc=iac,dc=local`, and make sure that these fields are filled:
  - `Personnal` > `Last name`, which might be the username
  - `Personnal` > `Email address`, which is used as email username, and should look like `<Last name>@<domain>`
  - `Unix` > `Primary Group` to `email-users`
  - `Set Password` button to define a temporary password, that the user should change by using `https://pwd-ldap.<root_domain>`
  - use webmail service, or any e-mail client (`https://webmail.<root_domain>`)

### Edge case on IaC's `docker-mailserver` reinstall (see #8)
Once `docker-mailserver` installed along OpenLDAP services, users wont be able to access their mails anymore, but still be able to login. That's because their owner `uid` has been replaced by `email-users` `guid` as primary owner of their folders containing mail data. To fix this, you might want to run the VSCode task `✅ mailserver: Ensure Mail Accounts Folder Permissions`.
