# cdash-docker
Docker container to run CDash with MariaDB

While Kitware themselves offer a Dockerfile within the CDash repository, I've
found theirs to be too complex to setup for a simple test. This is mostly a
trimmed version of Kitware's original Dockerfile as well as startup script, but
I've also added things to make it easier to get going.

## Building the container (optional)

To build, simply run

    docker build -t cdash .

## Starting CDash without persisting data

If all you'd like to do is test a few things and don't need projects and build
results to persist accross multiple starts of CDash, simply start the container
as a daemon with

    docker run -p <port>:80 -d --rm cdash

Then, open your browser and open `http://<hostname>:<port>/install.php` to set
up the admin user and you're good to go.

## Persisting the data

If you need to persist the data, mount a volume or filesystem under
/var/lib/mysql, e.g. by starting the container with

    docker run -p <port>:80 -d --rm --mount='src=cdash-database,dst=/var/lib/mysql/' cdash

Then, just like in the non-persistent case, open
`http://<hostname>:<port>/install.php` in your browser to set up the admin
user.

## HTTPS with letsencrypt

If you plan on having the CDash panel accessible from the internet it is a good
idea to also set up HTTPS, as otherwise login data will be sent over the internet
unencrypted.

To do so, follow the instructions at https://letsencrypt.org/getting-started/
to generate a certificate for the host where you'll be running the CDash
container from. Then, mounting the `/etc/letsencrypt/archive/<hostname>` folder
as `/certificates` will automatically trigger the usage of HTTPS.

Thus, putting everything together, the way to start a CDash instance with
persistent data and HTTPS is

    docker run -d --rm -p <port>:443 --mount'src=cdash-database,dst=/var/lib/mysql/' -v /etc/letsencrypt/archive/<hostname>:/certificates cdash

As in the other cases, the first time you're starting the container you'll
need to access `https://<hostname>:<port>/install.php` to set up the admin user.
