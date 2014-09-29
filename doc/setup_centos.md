# Devel setup on CentOS 6.5

This howto describe how to install latest version from RPM using installer 
and then migrate installed foreman and staypuft from git so you can easily
change source code and create pull requests.

We start by installing staypuft-installer from foreman nightly repositories

```sh
yum install -y http://mirror.pnl.gov/epel/6/i386/epel-release-6-8.noarch.rpm
yum install -y http://yum.theforeman.org/nightly/el6/x86_64/foreman-release.rpm
yum install -y foreman-installer-staypuft
```

Now we run the installer which and tell it to download latest discovery images
for us.

```
staypuft-installer --foreman-plugin-discovery-install-images=true
```

You will have to answer several questions. You should configure your NTP server,
users usually have issue if they are in VPN which restrict NTP to some internal 
server. Also it's common to configure DHCP Gateway to be the same as Host Gateway 
if you don't configure your staypuft machine to be the router. 

Precise networking configuration depends on your setup so you should verify that
all networking options make sense for you layout. Also I recommend setting your 
own password and/or ssh public key.

The above option makes staypuft-installer interactive; for non-interactive usage, 
explore `staypuft-installer --help`. Note that you would need to set up quite 
a lot of things manually if you want to run installer in non-interactive mode.

If you encounter issues during installation (failing DB migrations) and you rerun
the installer it won't remigrate your database. In such case there's a simple
workaround. Just run `echo >> ~foreman/config/database.yml` and the installer will
force migration and seed run.

One workaround is currently required for CentOS provisioning. After you login to
your foreman instnace you must update installation media path.
Go to Hosts -> Installation Media and update the path of the CentOS entry to:
"http://mirror.centos.org/centos/$major/os/$arch"
More information about the issue and it's status is [tracked here](http://projects.theforeman.org/issues/6884)

Now you should have foreman with staypuft running in production mode, 
now we'll have to run foreman with all plugins from git in development mode. The 
process consists of two steps, stage 1 running foreman from git and stage2 
running plugins from git.

## STAGE 1, getting foreman from git (may not be needed if you want to work on staypuft only)

We suppose that git is already installed. We clone the repo to /usr/share/foreman_git.
You can change this directory, just make sure you also modify other commands below.

```sh
cd /usr/share
git clone https://github.com/theforeman/foreman.git foreman_git
cp -a foreman/config/database.yml foreman_git/config/
cp -a foreman/config/settings.yaml foreman_git/config/
cp foreman/bundler.d/* foreman_git/bundler.d
```

Now we need to install dependencies so gems with native extensions will install correctly.

```sh
yum install -y gcc ruby193-ruby-devel ruby-devel libxml2 libxml2-devel libxslt libxslt-devel postgresql-libs postgresql-devel gcc-c++
cd foreman_git
chown foreman config.ru
scl enable ruby193 'bundle install --without sqlite mysql mysql2 libvirt vmware gce'
# get a coffee, bundle install will take some time
```

Some users reported nokogiri errors, to workaround, run this command first and then rerun bundle install
```sh
scl enable ruby193 'gem install nokogiri --no-ri --no-rdoc -- --use-system-libraries'
```

After your bundle install finished successfully you can continue with configuration changes.
```sh
sed -i s/production/development/ config/database.yml
ln -s /var/run/foreman tmp
touch log/development.log
chmod 0666 log/development.log
cd /etc/httpd/conf.d
sed -i "s#share/foreman/#share/foreman_git/#g" ./05-foreman.conf
sed -i 's#share/foreman$#share/foreman_git#g' ./05-foreman.conf
sed -i "s#share/foreman/#share/foreman_git/#g" ./05-foreman-ssl.conf
sed -i 's#share/foreman$#share/foreman_git#g' ./05-foreman-ssl.conf
echo 'RailsEnv development' > 05-foreman.d/passenger_env.conf
echo 'RailsEnv development' > 05-foreman-ssl.d/passenger_env.conf
service httpd restart
```

To be able to run rails console under SCL edit /usr/share/foreman_git/config/database.yml, and specify the host for the development db connection, otherwise Ident authentication will fail. It should look similar to this:
```yaml
development:
  adapter: postgresql
  host: localhost
  database: foreman
  username: foreman
  password: "foo"
```

## STAGE 2, getting staypuft from git

Now you're running foreman from git but all dependencies are installed as gems. 
If you want to work on plugins you may want to install them from git as well,
this howto describes the process for staypuft plugin but could be easily 
applied to other plugins as well.

```sh
cd /usr/share/
git clone https://github.com/theforeman/staypuft.git staypuft_git
echo "gem 'staypuft', :path => '/usr/share/staypuft_git'" > foreman_git/bundler.d/staypuft.rb
cd foreman_git
scl enable ruby193 'bundle install --without sqlite mysql mysql2 libvirt vmware gce'
service httpd restart
```

## DONE

Now you are running foreman and staypuft from git repositories. Foreman is 
configured to run in development environment so you can see debug level logs
and the code is automatically reloaded.

you can edit foreman in `/usr/share/foreman_git`
you can edit staypuft in `/usr/share/staypuft_git`
after each update of either foreman or staypuft from git, don't forget to run:
```sh
bundle exec rake db:migrate
bundle exec rake db:seed
```

This will make sure that your database is up to date.
To restart the application (it's running in development env) just `touch tmp/restart.txt`

Make sure you run all of these commands in you foreman_git repo.

