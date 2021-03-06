# config valid for current version and patch releases of Capistrano
lock "~> 3.11.0"

set :application, "blue_green_deployment_demo"
set :repo_url, "git@github.com:8thlight/blue_green_deployment.git"

# Default branch is :master
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default deploy_to directory is /var/www/my_app_name
# set :deploy_to, "/var/www/blue_green_deployment_staging"
after 'git:check', 'deploy:set_deploy_to'
namespace :deploy do
  task :set_deploy_to do
    on roles(:app) do
      deploy_to = capture(:readlink, '/var/www/blue_green_deployment_staging')
      set :deploy_to, deploy_to
    end
  end
end

# Default value for :format is :airbrussh.
# set :format, :airbrussh

# You can configure the Airbrussh format using :format_options.
# These are the defaults.
# set :format_options, command_output: true, log_file: "log/capistrano.log", color: :auto, truncate: :auto

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
# append :linked_files, "config/database.yml"

# Default value for linked_dirs is []
append :linked_dirs, "shared/pids"
# append :linked_dirs, "log", "tmp/pids", "tmp/cache", "tmp/sockets", "public/system"

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for local_user is ENV['USER']
# set :local_user, -> { `git config user.name`.chomp }

# Default value for keep_releases is 5
# set :keep_releases, 5

# Uncomment the following to require manually verifying the host key before first deploy.
# set :ssh_options, verify_host_key: :secure

set :unicorn_config_path, -> { File.join(current_path, "config", "unicorn.rb") }
set :unicorn_pid, -> { File.join(current_path, "shared", "pids", "unicorn.pid") }

after 'deploy:publishing', 'deploy:restart'
namespace :deploy do
  task :restart do
    invoke 'unicorn:reload'
  end
end

namespace :deploy do
  task :promote_release do
    prefix = "/var/www"
    on roles(:app) do
      staging = capture(:readlink, "#{prefix}/blue_green_deployment_staging")

      if staging == "#{prefix}/blue_green_deployment_blue"
        new_staging = "green"
        new_release = "blue"
      else
        new_staging = "blue"
        new_release = "green"
      end
      execute(:sudo, :ln, "-sfn", "#{prefix}/blue_green_deployment_#{new_release}", "#{prefix}/blue_green_deployment_release")
      execute(:sudo, :ln, "-sfn", "#{prefix}/blue_green_deployment_#{new_staging}", "#{prefix}/blue_green_deployment_staging")
    end
  end
end
