# Qalisa's IaC (Infrastructure as Code)
Mainly scripts to automatize the setup of our simple, 1 master-node opinionated k8s infrastructure. 
Also includes automation scripts to install on-premise services too heavy to sit on k8s clusters alone.

> [!TIP]
> This Ansible directory layout follows current best practices (https://docs.ansible.com/ansible/2.8/user_guide/playbooks_best_practices.html#directory-layout).

## Considerations
- Using `VSCode` is highly recommanded, as configured tasks exist to help you leverage this repo. Automatic recommanded extensions are also available. In the following documentation, we expect you to be using VSCode from here.
- These Ansible scripts are expected to be executed on Debian-based Linux targets. 
- Our recommanded way of executing these scripts is through Ansible EE images (https://docs.ansible.com/ansible/latest/getting_started_ee/index.html). As such, make sure you have `Docker Desktop` (Windows), `OrbStack` (MacOs), `docker` (Ubuntu, https://docs.docker.com/engine/install/ubuntu/) or equivalent installed on your local OS to build those.
- Using Ansible, to connect to your remote machines on which you wish to interact, we recommand using authorized SSH keys generated with `ssh-keygen` (https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent). Make sure to generated those 
- Since production vars are intentionnaly opted-out of source control (for security reasons obviously), we recommand you to clone this repository on a personal & secure, remotely-synced cloud service like `Google Drive`.

## How-To use

### 1. Prepare your machine (dev tools, EE image...)
- Have `git` installed on your machine; then, `git clone {this repo}` in your terminal and open the project.
- Launch the VSCode Task `⛏0. Install Builder Dependencies`.
- Launch the VSCode Task `⛏1. Install Ansible Tools`.
- Launch the VSCode Task `⛏2. Build EE`.

### 2. Configure
> [!TIP]
> Check `ansible/inventories/example/*` to have a grasp on how to configure your inventory in its `ansible/inventories/production/*` counterpart.

- Review `ansible/playbooks/_.site.services.yml`, and comment / uncomment services you wish to have installed or not on the remote machine.
- Define an `ansible/production/hosts.yaml` file, with machine(s) on group named `k3s_master` on which you want to install your cluster and services.
- According to `ansible/production/group_vars/all/*` files, declare appropriate and expected `ansible/production/{group_vars,host_vars}/*/{vars,vault}` files, and variables within them. Not all variables are required depending on services you wish to use.

### 3. Run
- Install the k3s master node with bare minimum features using the VSCode Task `🚀 Install: k3s`. 
- Install previously selected services using the VSCode Task `🚀 Install: Services`. 

### Optionnal - securing sensitive informations with `ansible-vault`
As an alternative, you can leverage `ansible-vault` to encrypt your ansible sensitive `group_vars/<*>/vault` / `host_vars/<*>/vault` informations.
- Create a `./.ansible-vault-pw` file, containing a password to secure all the secrets related to this stack within ansible vault technology
- Encrypt `./ansible/inventories/group_vars/all/vault` using VSCode Task `🔒 Ansible Vault: Encrypt`.
- If you want to update values, decrypt the files using VSCode Task `🔒 Ansible Vault: Decrypt`.

## Overlook of available services
Have a look at `playbooks/_.site.services.yml` to review all availables roles.
Once cluster is setup, you can review all availables services through `https://book.<root_domain>`.

## Tips about services

### `Odoo` - in case of multiple database
If and only if having multiple odoo databases on your postgres: when sending invoices, you might encounter 404 from your client, it is because `odoo.conf`'s `db_filter` is not configured correctly. You might want to only use one database per Odoo instance.

https://github.com/Qalisa/IaC/issues/37

### `Odoo` - In case of restoring a backup
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

### `LDAP / mail` - Create new users
By default, only 2 users are created: `postmaster` and `donotreply`, which are required. If you want to create more:
- Use LAM service (`https://admin-ldap.<root_domain>`), and login as admin.
- Create a new user in `ou=<domain>,cn=email-users,dc=iac,dc=local`, and make sure that these fields are filled:
  - `Personnal` > `Last name`, which might be the username
  - `Personnal` > `Email address`, which is used as email username, and should look like `<Last name>@<domain>`
  - `Unix` > `Primary Group` to `email-users`
  - `Set Password` button to define a temporary password, that the user should change by using `https://pwd-ldap.<root_domain>`
  - use webmail service, or any e-mail client (`https://webmail.<root_domain>`)

### `LDAP / mail / SMTP` - SMTP Trafic and SMTP providers (Outlook, Gmail...) network trust checks
Use https://www.mail-tester.com/, https://www.helloinbox.email/ or https://mxtoolbox.com/emailhealth to test trustness of IaC mail installation.
- Some Server Providers / ISPs disable SMTP outbound trafic, preventing from sending mail. Please act accordingly to enable it.
  - Scaleway: https://www.scaleway.com/en/docs/elastic-metal/how-to/enable-smtp/
- Some providers might require (rDNS) or PTR to match to route SMTP trafic from this server. Make it so it matches the mail.<root_domain> domain name.
  - https://mxtoolbox.com/ReverseLookup.aspx to test correctness
  - Scaleway: https://www.scaleway.com/en/docs/elastic-metal/how-to/configure-reverse-dns-flexible-ip/
- postmaster tools:
  - https://postmaster.google.com/managedomains?pli=1
  - https://sendersupport.olc.protection.outlook.com/snds/index.aspx

### `mail` - In case of issues regarding access Dovecot rights
https://doc.dovecot.org/2.3/admin_manual/filesystem_permission/#permissions-to-new-domain-user-directories
We use a custom `user-patches.sh` to ensure permissions are correctly set at startup (`roles/k8s__docker_mailserver/template/mailserver/dms/user-patches.sh.j2`); if encountering errors, a basic reboot should fix this.

### `ArgoCD` - orchestration of organization-developped services
To use ArgoCD, you need to provide an `app-of-apps` repository in your Github Organization (https://argo-cd.readthedocs.io/en/stable/operator-manual/cluster-bootstrapping/). You'll kind the default name of said repo to create on `group_vars`'s `argocd__app_of_apps__repo_name`.
You can use `Qalisa/argocd-repository` as template on how to use it in real-life example.




