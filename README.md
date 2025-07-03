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

### In case of issues regarding access Dovecot rights
https://doc.dovecot.org/2.3/admin_manual/filesystem_permission/#permissions-to-new-domain-user-directories
We use a custom `user-patches.sh` to ensure permissions are correctly set at startup (`roles/k8s__docker_mailserver/template/mailserver/dms/user-patches.sh.j2`); if encountering errors, a basic reboot should fix this.


## Outdated supplementary services
There is 2 services that are shipped with IaC but we do not recommend to use, but still keep them for documentary purposes:

- Matomo, which helps tracking visitors and other data of installed services
  - > Outdated feature-wise, prefer using PostHog Cloud free tier, or self-hosted on another node https://posthog.com/docs/self-host
- Sentry, which tracks live bugs on services
  - > Heavy on resources on a Single Node, should prefer external use of official on-premise https://develop.sentry.dev/self-hosted/ on another node

## ArgoCD - orchestration of organization-developped services
To use ArgoCD, you need to provide an `app-of-apps` repository in your Github Organization (https://argo-cd.readthedocs.io/en/stable/operator-manual/cluster-bootstrapping/). You'll kind the default name of said repo to create on `group_vars`'s `argocd__app_of_apps__repo_name`.
You can use `Qalisa/argocd-repository` as template on how to use it in real-life example.

## Odoo - in case of multiple database
If and only if having multiple odoo databases on your postgres: when sending invoices, you might encounter 404 from your client, it is because `odoo.conf`'s `db_filter` is not configured correctly. You might want to only use one database per Odoo instance.

https://github.com/Qalisa/IaC/issues/37

## Odoo 
### In case of restoring a backup
- Regarding Addons:
  - If your backup expects some addons to be installed on your Odoo instance, especially if those are heavy, please install them before restoring; you might dodge a timeout which can break your recovery.
- Regarding Postgres DB comming with Odoo: 
  - You might want to disable StatefulSet probes (`livelinessProbe` espacilly), because of intensive backup operations might render it unresponsive, which would result in an unwanted automatic-restart.
  - Along with it, you might want to set `primary.resourcesPreset` to `large` at least. It will boost speed of backup recovery and would prevent DB to hand and stop unexpectedly under pressure, which would break database recovery altogether.
- Regarding `/web/database/restore`
  - If you are using Cloudflare's proxying feature or similar, which includes default timeouts sub 100 secs, this might break your database recovery process. Disable this temporary.
    - https://www.reddit.com/r/webdev/comments/kzgozy/til_you_can_type_thisisunsafe_on_chrome_ssl_error/
- Regarding Odoo configuration:
  - If after recoverying, you do not see your recovered database, You might want to set `odoo.conf`'s `db_name` to `False`.
  - If Odoo is too slow, you can tweak these values: https://www.odoo.com/documentation/18.0/administration/on_premise/deploy.html#id4
- Regarding using `local-path` StorageClass
  - `capacity` has no effect (https://github.com/rancher/local-path-provisioner?tab=readme-ov-file#cons)