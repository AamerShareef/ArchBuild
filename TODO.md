# To-Do

## Automate Tools Configurations

### metasploit Configuration

```
sudo pacman -S postgres
sudo su -l postgres
initdb -D /var/lib/postgres/data
sudo systemctl start postgresql.service
createuser --interactive
createdb msf
msfconsole
vim .msf4/database.yml

echo "production:
  adapter: postgresql
  database: msf
  username: msf
  password:
  host: localhost
  port: 5432
  pool: 5
  timeout: 5 " > .msf4/database.yml
```

## Automate Firefox plugin installions

about:config
layers.acceleration.force-enabled = true
network.security.ports.banned.override
add values 1-65535

*Plugins:* Foxy Proxy Ublock origin
