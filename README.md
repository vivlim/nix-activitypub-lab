# viv's activitypub testing lab

runs a nixos vm containing multiple containers with various servers on them. there's also an extremely scuffed webpage for conveniently checking on logs and such.

you can access the instances by using the `localtest.me` domain, which redirects to localhost.

## usage

### setting up port 443
first, we need to run socat as root to forward port localhost:443 to localhost:60443.
you can do that conveniently with:
```
nix run .#tunnel-port
```
in another terminal. now when the vm starts, you'll be able to access caddy.

### starting the vm
this will build the configuration and launch qemu:
```
nix run
```

qemu will be listening on localhost:60443, which will be forwarded to the vm on port 443, where caddy is running. caddy will then reverse proxy to the appropriate server.

while the vm is running (and caddy is working, and socat is running) you'll be able to go to https://ap-lab.localtest.me which has some handy links for checking different logs, restarting services, resetting gts instances, and so on.

the first time you launch the vm you should click the reset links for each gts instance, which will wipe out the db and create an admin user with the credentials specified in `consts.nix`.
currently those credentials are:
username: `test`
email: `test@localhost`
password: `correct-horse-battery-staple` (i would've used something shorter but passwords that are too short are rejected by gts)

if you make any changes to the config, you'll need to shutdown the vm and `nix run` again (this is why i made a convenient shutdown button on the webpage)

### how can i add more instances?
1. add another hostname and ip in `consts.nix`
2. copy an existing container in `containers.nix` and reference the new values. make sure to update the list of hosts entries and the activation script
3. update `www.nix` so caddy reverse proxies to it

### how's that 'admin panel' work?
it's a static webpage (`/www/index.html`) and is powered by shell2http, see `www.nix`. :)
