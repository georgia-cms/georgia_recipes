Capistrano::Configuration.instance.load do

  set_default(:newrelic_api_key) { ask('What is your NewRelic API key?') }

  namespace :newrelic do
    desc "Install Newrelic Server Monitor"
    task :install, roles: :app do
      run "echo 'deb http://apt.newrelic.com/debian/ newrelic non-free' | #{sudo} tee -a /etc/apt/sources.list.d/newrelic.list"
      run "#{sudo} wget -O- https://download.newrelic.com/548C16BF.gpg | #{sudo} apt-key add -"
      run "#{sudo} apt-get update"
      run "#{sudo} apt-get -y install newrelic-sysmond"
    end
    after "deploy:install", "newrelic:install"

    task :setup, roles: :app do
      run "#{sudo} nrsysmond-config --set license_key=#{newrelic_api_key}"
      restart
    end

    task :start, roles: :app  do
      run "#{sudo} service newrelic-sysmond start"
    end

    task :stop, roles: :app  do
      run "#{sudo} service newrelic-sysmond stop"
    end

    task :restart, roles: :app do
      stop
      start
    end

    task :uninstall, roles: :app do
      stop
      run "#{sudo} apt-get remove newrelic-sysmond"
    end
  end

end