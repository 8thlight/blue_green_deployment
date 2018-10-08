Remind the students
* Start simple! One box, two deploys
* One DB is fine, and probably better at the start
* Get things into source - they may work on an EC2 box for configs, etc.
* Run locally! Footprints has unicorn, but doesn't work with it (yet)
* As many defaults as you can

# Gotchas
I didn't setup symlinks like capistrano-rails suggests, at least not yet, because I know you run into the unicorn.pid issue.

### ssh
https://capistranorb.com/documentation/getting-started/authentication-and-authorisation/

If you login as `ubuntu` you are not the root user, so you'll need to sudo commands until you `sudo su - deploy`. Or you can `su -` to be the `root` user, matching the directions.

I started with a workstation ssh key that I had. I did create the deploy user as listed here. I did NOT make a public key with a password and use ssh-agent, although I probably should have. I did need to make sure to explicitly add my Amazon PEM file with `ssh-add ~/.ssh/elk-stack.pem`. Then I added that key manually to the authorized keys on deploy (without bothering to use `ssh-copy-id`).

### Dependencies

To install ruby I logged in as ubuntu and installed make, build-essential, libsqilte3-dev, libssl1.0-dev via apt with sudo. Then use the [directions](https://github.com/postmodern/chruby) to install chruby. Use the `wget` directions since there is not an apt package. Make sure you use the System Wide configuration and

```
if [ -n "$BASH_VERSION" ] || [ -n "$ZSH_VERSION" ]; then
  source /usr/local/share/chruby/chruby.sh
fi
```
to the `/etc/profile.d/chruby.sh` file.


Next you can install `ruby-build` - don't use apt! Use the git clone approach. Then install ruby 2.2.9 via the command `ruby-build 2.2.9 /opt/rubies/ruby-2.2.9`. At the end of the `~/.bash_profile` for the `ubuntu` and `deploy` users add `chruby ruby-2.2.9`.

Next logout and login as the `deploy` user and install bundler with `gem install bundler`. Finally at the top of the `.bashrc` for the `deploy` put:

```
source /usr/local/share/chruby/chruby.sh
chruby 2.2.9
```

This is terrible, but it works.

Next it's time for nginx. Installed it with apt (as the ubuntu user).

I used https://www.digitalocean.com/community/tutorials/how-to-deploy-a-rails-app-with-unicorn-and-nginx-on-ubuntu-14-04 as a guideline and it mostly worked. I had to put what is documented https://stackoverflow.com/questions/23180650/how-to-solve-error-missing-secret-key-base-for-production-environment-rai into etc/environment. Figure that out for an Ansible deploy.

### Blue Green

After getting it deployed you needed to get to a blue green. First I renamed `blue_green_deployment` to `blue_green_deployment_blue`. Then I created a symbolic link called `blue_green_deployment_staging` and set the deploy to that. Finally I updated the nginx config and it all worked.

Next I created a `blue_green_deployment_green` and moved the symlink for `blue_green_deployment_staging` to point at it. This began giving a bad gateway, because the files were gone. I then deployed to staging, and it worked.
You can move a symlink with `ln -sfn` to remove and recreate, with a flag to say it's a directory.

I then created a `blue_green_deployment_release` symlink and pointed it at `blue_green_deployment_blue`. Boom, two deploys.

The final trick was dynamically making sure that I always used 'staging' for deployments. This could cause issues when switching back and forth, because the symbolic links that capistrano would create would say 'staging'. When you switched staging and release, the capistrano links would be broken. I fixed that with the following:

```
after 'git:check', 'deploy:set_deploy_to'
namespace :deploy do
  task :set_deploy_to do
    on roles(:app) do
      deploy_to = capture(:readlink, '/var/www/blue_green_deployment_staging')
      set :deploy_to, deploy_to
    end
  end
end
```

Interestingly switching the symbolic links worked immediately, without the need for a `nginx` restart. It did require putting the deploy user in the sudoers file, for the `ln` command. See here: https://superuser.com/questions/68685/chown-is-not-changing-symbolic-link.

# Reading
https://devcenter.heroku.com/articles/rails-unicorn

https://github.com/capistrano/capistrano
https://github.com/capistrano/rails
