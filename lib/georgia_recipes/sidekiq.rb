Capistrano::Configuration.instance.load do

  set_default(:sidekiq_pid) { "#{shared_path}/pids/sidekiq.pid" }
  set_default(:sidekiq_log) { "#{shared_path}/log/sidekiq.log" }

  namespace :sidekiq do

    task :setup, roles: :app do
      template("sidekiq.erb", "/tmp/sidekiq")
      run "#{sudo} mv -u /tmp/sidekiq /etc/init/sidekiq.conf"
    end

    desc "Generate a 'default' sidekiq.yml configuration file."
    task :config, roles: :app do
      run "mkdir -p #{shared_path}/config"
      template "sidekiq.yml.erb", "#{shared_path}/config/sidekiq.yml"
    end

    desc "Symlink the database.yml file into latest release"
    task :symlink, roles: :app do
      run "ln -nfs #{shared_path}/config/sidekiq.yml #{release_path}/config/sidekiq.yml"
    end
    after "deploy:finalize_update", "sidekiq:symlink"

    desc "Clear Sidekiq Retry Queue"
    task :clear_queue, roles: :app do
      run "cd #{current_path} && bundle exec rake sidekiq:clear_queue RAILS_ENV=#{rails_env}"
    end

  end
end