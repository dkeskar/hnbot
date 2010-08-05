set :application, "watchbots"
set :user, "app"
set :deploy_to, "/home/#{user}/#{application}"
set :scm, :git
default_run_options[:pty] = true
set :repository,  "git@track.memamsa.net:watchbots.git"
set :branch, "master"
set :deploy_via, :remote_cache
set :git_enable_submodules, 1
set :use_sudo, false

role :app, "nyx.memamsa.com"
role :web, "nyx.memamsa.com"
role :db,  "nyx.memamsa.com", :primary => true

after "deploy:symlink", "deploy:update_crontab"

namespace :deploy do
  task :start do ; end
  task :stop do ; end
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "touch #{File.join(current_path,'tmp','restart.txt')}"
  end
  
  desc "Update the crontab file"
  task :whenever, :roles => :db do
    run "cd #{release_path} && whenever --set 'environment=production&cron_log=#{shared_path}/log/cron.txt' && whenever --update-crontab #{application}"  
  end
# if you're still using the script/reapear helper you will need
# these http://github.com/rails/irs_process_scripts

end