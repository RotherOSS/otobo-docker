# Basic container for testing LDAP integration in OTOBO

- starts a container running LDAP within the otobo\_default network
- the used Docker image is https://hub.docker.com/r/osixia/openldap
- see testing/openldap/Config.pm.example for basic config
- otobo auth works
- user + role mapping works - see Config.pm.example for mapping
- ldap is bootstraped from testing/openldap/data/bootstrap.ldif, add new users / groups there

## OTOBO Config

- add Config.pm.example content to Kernel/Config.pm
- disable 'CheckEmailAddresses' in SysConfig, or change the testuser's email in testing/openldap/data/bootstrap.ldif

## test credentials out of the box:

### admin user

username: testadmin
pwd: testadmin

### agent user

username: testagent
pwd: testagent

## Inspect LDAP

See the sample commands in testting/openldap/lds.




