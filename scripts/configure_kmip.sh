TOKEN=`grep Token /var/intvault/rec.key | awk -F':' '{print $NF}'`
echo $TOKEN
vault login $TOKEN
# enable kmip SE
vault secrets enable kmip

# configure kmip 
#vault write kmip/config listen_addrs=0.0.0.0:5696

vault write kmip/config listen_addrs=0.0.0.0:5696 \
server_hostnames="vaultlb,vaults0,vaults1,vaults2" \
server_ips="10.10.20.23,10.10.42.203,10.10.42.200,10.10.42.201,10.10.42.202"


# get ca cert
mkdir /vagrant/certs
#mkdir /vagrant/mysql
cd /vagrant/certs

vault read kmip/ca -format=json | jq -r  .data.ca_pem > ca.pem

# set scope
vault write -f kmip/scope/finance

# permissions

vault write kmip/scope/finance/role/accounting operation_all=true

# get creds
vault write -format=json \
kmip/scope/finance/role/accounting/credential/generate \
format=pem > credential.json

# generate client certs and keys
jq -r .data.certificate < credential.json > cert.pem

jq -r .data.private_key < credential.json > key.pem



# get role keys
vault list kmip/scope/finance/role/accounting/credential



## for mysql, hashed
# Setup scopes and roles
#vault write -f kmip/scope/scope1
#vault write kmip/scope/scope1/role/role1 operation_all=true

# Generate credentials for the role.
#vault write -format=json -f kmip/scope/scope1/role/role1/credential/generate | jq -r '.data | to_entries | .[] | map_values(if type=="string" then . else (. | join("\n")) end)' | jq -s 'from_entries' > /vagrant/mysql/creds.json
