# Blue Green Deployment Example

This is meant to be an example of Blue/Green deployments, done with nginx, unicorn and capistrano. Pretty simple.

## How does it work

Nginx is serving up two Rails apps. One on port 80, the other on port 81. Port 80 is release, found at `blue_green_deployment_release` which is a symbolic link to either `blue` or `green`. Port 81 is staging, found at `blue_green_deployment_staging` which is always a symbolic link. Running `cap production deploy` always deploys to the staging environment (yes this is misleading) but it has a trick. It uses `readlink` to dynamically found out what staging is pointing too, and sets that as the deploy\_to  directory. If you don't do this, then the `current` symbolic link will eventually point to a directory at `staging\releases` which will be wrong when you swap symbolic links.

Ugh it's confusing, see the picture below.

After staging is production ready, you "deploy" production simply by running `promote_release` which swaps the symbolic links. Nginx does not need to be restarted - all requests will now go to new release environment. The old release enenvironment becomes staging. You'll want to deploy staging after this, to get it caught up.

## Gotchas

I left my notes in, in a file called Notes.MD. But let me put in a few of the issues I had:

- Getting Ruby installed via with chruby was a huge pain in the butt. See my notes for details.
- Getting an environment variable for `SECRET_KEY_BASE` required changing `/etc/environment`. This is hacky and should be fixed.
- You needed to make sure that the `deploy` user have sudo access to the `ln` command. Again see the ./Notes.md file.
- I'm not sure this will work out of the box on a new machine, you may need to do some fiddling with directories. Again see the ./Notes.md file.
