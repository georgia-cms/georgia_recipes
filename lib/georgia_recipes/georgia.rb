Capistrano::Configuration.instance.load do
  namespace :georgia do

    desc "Install rails stack onto the server for Georgia CMS"
    task :install do
      base.install
    end
    before "georgia:install", "locale:setup"
    after "georgia:install", "rbenv:install"
    after "georgia:install", "chef:install"
    after "georgia:install", "monit:install"
    after "georgia:install", "imagemagick:install"
    after "georgia:install", "nodejs:install"
    after "georgia:install", "nginx:install"
    after "georgia:install", "pg:install"
    after "georgia:install", "memcached:install"
    after "georgia:install", "newrelic:install"

    task :setup do
      # Trigger callbacks for setting up a rails stack after install
    end
    after "georgia:setup", "memcached:setup"
    after "georgia:setup", "nginx:setup"
    after "georgia:setup", "pg:setup"
    after "georgia:setup", "unicorn:setup"
    after "georgia:setup", "monit:setup"
    after "georgia:setup", "newrelic:setup"

    task :seed, roles: :web do
      run "cd #{current_path} && bundle exec rake georgia:seed RAILS_ENV=#{rails_env}"
    end

    desc "Run georgia:upgrade task"
    task :upgrade, roles: :web do
      run "cd #{current_path} && bundle exec rake georgia:upgrade RAILS_ENV=#{rails_env}"
    end

    task :create_indices, roles: :web do
      run "cd #{current_path} && bundle exec rake georgia:create_indices RAILS_ENV=#{rails_env}"
    end

  end
end