Capistrano::Configuration.instance.load do

  namespace :logrotate do

    desc "Setup log rotation for Rails app log files"
    task :setup, roles: :web do
      template("logrotate.erb", "/tmp/logrotate_conf")
      run "#{sudo} mv -u /tmp/logrotate_conf /etc/logrotate.d/#{application}"
      run "#{sudo} chown root:root /etc/logrotate.d/#{application}"
    end

    desc "Runs logrotate with default config file"
    task :start, roles: :web do
      run "#{sudo} logrotate /etc/logrotate.conf"
    end
  end

end