Capistrano::Configuration.instance.load do

  namespace :logrotate do
    desc "Setup log rotation for Rails app log files"
    task :setup, roles: :web do
      template("logrotate.erb", "/tmp/logrotate_conf")
      run "#{sudo} mv -u /tmp/logrotate_conf /etc/logrotate.d/#{application}"
    end
  end

end