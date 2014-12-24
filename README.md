Hypercheese Photo Organizer
===========================

Hypercheese is a photo organizer and gallery written in rails.  It lets you
organize large photo collections from multiple sources.

## Deploy your own instance

### Installation

#### Ubuntu 14.04
```bash
$ git clone git@github.com:jewel/hypercheese.git -b ember
$ cd hypercheese
$ sudo apt-get install bundler ruby-dev libmysqlclient-dev libsqlite3-dev build-essential nodejs
$ bundle install
$ rake secret > .secret_key_base
# seed the database with the default user:pwd of admin@example.com:password
$ rake db:seed
$ rails server
# You can now browse to http://localhost:3000 and login!
```

### Import your photos

Import your existing photos like this:

```bash
$ sudo apt-get install imagemagick libjpeg-turbo-progs
# photos must exist in ./originals/, so use a symlink to get them there
$ ln -s ~/Pictures originals/${USER}_pictures

# Make sure to put a trailing slash at the end of your path!
$ bundle exec script/import originals/${USER}_pictures/
```
