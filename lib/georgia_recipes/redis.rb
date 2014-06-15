Capistrano::Configuration.instance.load do

  namespace :redis do

    desc "Install Redis"
    task :install, roles: :app do
      run "#{sudo} apt-get -y update"
      run "#{sudo} apt-get -y install redis-server"
    end

    desc "Uninstall Redis"
    task :uninstall, roles: :app do
      run "#{sudo} apt-get -y remove redis-server"
    end

    desc "Start Redis Server"
    task :start, roles: :app do
      run "redis-server"
    end

  end

end