Capistrano::Configuration.instance.load do

  namespace :redis do

    desc "Install Redis"
    task :install, roles: :app do
      run "#{sudo} apt-get -y update"
      run "#{sudo} apt-get -y install redis-server"
    end


    desc "Setup redis-server"
    task :setup, roles: :web do
      run "#{sudo} update-rc.d redis-server disable"
      template("redis.erb", "/tmp/redis_conf")
      run "#{sudo} mv -u /tmp/redis_conf /etc/init/redis-server.conf"
    end

    desc "Uninstall Redis"
    task :uninstall, roles: :app do
      run "#{sudo} apt-get -y remove redis-server"
    end

    desc "Start Redis Server"
    task :start, roles: :app do
      run "redis-server"
    end

    %w(start stop restart).each do |command|
      task command, roles: :app do
        run "#{sudo} #{command} redis-server"
      end
    end

  end

end