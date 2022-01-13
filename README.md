## Repo to setup and test vault kmip secret engine behaviour


- Guide to install HashiCorp Enterprise License - https://learn.hashicorp.com/tutorials/nomad/hashicorp-enterprise-license?in=vault/enterprise

- https://support.hashicorp.com/hc/en-us/articles/4403072322707-How-to-install-license-in-Vault-DR-cluster-in-vault-running-1-7-x-version-and-prior


#### Documentation


#### Prerequisites

- Working Vagrant setup
- 8 Gig + RAM workstation as the (all together) Vms use 5 vCPUS and 5+ GB RAM

- Download vault ent binary from https://releases.hashicorp.com/vault/ and store it in `ent/` directory. 


#### quick setup

-  clone repo

```
git clone https://github.com/ArunNadda/vault_kmip_setup.git
cd vault_kmip_setup
```
- download vault ent binary 

```
% cd ent
ent % ls
readme.md

ent % wget -q https://releases.hashicorp.com/vault/1.x.x+ent/vault_1.x.x+ent_linux_amd64.zip
% ls -l
total 164384
-rw-r--r--  1 anadda  staff       116  6 Sep 09:20 readme.md
-rw-r--r--  1 anadda  staff  77777777 27 Aug 08:56 vault_1.x.x+ent_linux_amd64.zip
```
- start vault VM nodes using vagrant, this command setup a vault clusters - a 3node cluster with kmip secret engine enbaled and configured and a 1 node mongodb node

```
cd ..
vagrant up

# check status 
vagrant status
```


### below example to setup 1 node vault cluster and 1 node mongodb setup using vault KMIP to encrypt data

- start 1 node vault cluster and mongodb node

```
vagrant up vaults0 vaults3
vagrant status
```

- login to vault node
vagrant ssh vaults0


### env setup details

- vault service is started with `EnvironmentFile`, which has parameters related to KMIP setup

```
$ sudo cat /etc/systemd/system/vault.service
[Unit]
Description="Vault secret management tool"
Requires=network-online.target
After=network-online.target
ConditionFileNotEmpty=/etc/vault/vault.hcl

[Service]
User=vault
Group=vault
PIDFile=/var/run/vault/vault.pid
EnvironmentFile=/var/transit/vtoken.tok
ExecStart=/usr/local/bin/vault server -config=/etc/vault/vault.hcl
StandardOutput=file:/var/log/vault/vault.log
StandardError=file:/var/log/vault/vault.log
ExecReload=/bin/kill -HUP
KillMode=process
KillSignal=SIGINT
Restart=on-failure
RestartSec=42
TimeoutStopSec=30
StartLimitInterval=60
StartLimitBurst=3
LimitMEMLOCK=infinity

[Install]
WantedBy=multi-user.target
```

- vault service started with below KMIP debug parameters enabled. All KMIP related operations will be verbose logs in vault operational logs.

```
vagrant@vaults0:~$ cat /var/transit/vtoken.tok
VAULT_TOKEN=s.xxx
KMIP_CONNECTION_DEBUGGING=1
KMIP_REQUEST_DEBUGGING=1
KMIP_RESPONSE_DEBUGGING=1
KMIP_DECODING_DEBUGGING=1
KMIP_INDEX_DEBUGGING=1


$ sudo cat /proc/4016/environ
LANG=C.UTF-8PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/binHOME=/etc/vaultLOGNAME=vaultUSER=vaultSHELL=/bin/falseINVOCATION_ID=32bbb9e87ed04833830624b6bf4a5e5eVAULT_TOKEN=s.aGzyTg2a9sEQEKwLcW4W8MwXKMIP_CONNECTION_DEBUGGING=1KMIP_REQUEST_DEBUGGING=1KMIP_RESPONSE_DEBUGGING=1KMIP_DECODING_DEBUGGING=1KMIP_INDEX_DEBUGGING=1
```

- get vault logs

```
sudo tail -f /var/log/vault/vault.log
```



### kmip config in vault. `vaultlb` is added to hostnames and `10.10.20.23` IP is added which is haproxy running on `vaults3`. This is to test vault kmip behariour from loadbalancer in front of cluster.

```
$ vault read kmip/config
Key                            Value
---                            -----
default_tls_client_key_bits    256
default_tls_client_key_type    ec
default_tls_client_ttl         336h
listen_addrs                   [0.0.0.0:5696]
server_hostnames               [vaultlb vaults0 vaults1 vaults2]
server_ips                     [10.10.20.23 10.10.42.203 10.10.42.200 10.10.42.201 10.10.42.202]
tls_ca_key_bits                256
tls_ca_key_type                ec
tls_min_version                tls12
vagrant@vaults0:~$ cat /etc/hosts
127.0.0.1	localhost

# The following lines are desirable for IPv6 capable hosts
::1	ip6-localhost	ip6-loopback
fe00::0	ip6-localnet
ff00::0	ip6-mcastprefix
ff02::1	ip6-allnodes
ff02::2	ip6-allrouters
ff02::3	ip6-allhosts
127.0.1.1	ubuntu-bionic	ubuntu-bionic

127.0.2.1 vaults0 vaults0
10.10.42.200 vault0
10.10.42.201 vault1
10.10.42.202 vault2
10.10.42.203 vault3
10.10.20.23 vaultlb
```


- node running mongodb is vaults3, ssh to this node

```
vagrant ssh vaults3
```


- check for below logs on mongodb node `/var/log/mongodb/mongod.log`. Below specific line shows mongodb is using KMIP and KMIP key can be seen in logs.



```
{"t":{"$date":"2022-01-13T02:23:11.774+00:00"},"s":"I",  "c":"STORAGE",  "id":24199,   "ctx":"initandlisten","msg":"Created KMIP key","attr":{"keyId":"QQl32MEBuq95GAEeLN4ayPjsNjSQ6twb"}}
{"t":{"$date":"2022-01-13T02:23:11.843+00:00"},"s":"I",  "c":"STORAGE",  "id":24207,   "ctx":"initandlisten","msg":"Opening WiredTiger keystore","attr":{"config":"create,compatibility=(release=2.9),config_base=false,checkpoint=(wait=60),log=(enabled,file_max=3MB),transaction_sync=(enabled=true,method=fsync),extensions=[local={entry=mongo_addWiredTigerEncryptors,early_load=true},],encryption=(name=AES256-CBC,keyid=.master),"}}
```




### Other commands to manage setup

#### check vagrant status, there are 4 nodes defined in vagrant file. 

```
 % vagrant status
Current machine states:

vaults0                   not created (virtualbox)
vaults1                   not created (virtualbox)
vaults2                   not created (virtualbox)
vaults3                   not created (virtualbox)

This environment represents multiple VMs. The VMs are all listed
above with their current state. For more information about a specific
VM, run `vagrant status NAME`.
```


#### to shutdown

```
vagrant halt
```


#### to start again

```
vagrant up
```

#### to destory the setup

```
vagrant destory -f
```


