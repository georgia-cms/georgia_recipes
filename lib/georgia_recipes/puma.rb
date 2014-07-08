Capistrano::Configuration.instance.load do

  namespace :puma do

    set_default(:puma_user) { user }
    set_default(:puma_pid) { "#{current_path}/tmp/pids/puma.pid" }
    set_default(:puma_config) { "#{shared_path}/config/puma.rb" }
    set_default(:puma_log) { "#{shared_path}/log/puma.log" }

    desc "Setup Puma initializer and app configuration"
    task :setup, roles: :app do
      run "mkdir -p #{shared_path}/config"
      template "puma.rb.erb", puma_config
      template "puma_init.erb", "/tmp/puma_init"
      run "chmod +x /tmp/puma_init"
      run "#{sudo} mv /tmp/puma_init /etc/init.d/puma_#{application}"
      run "#{sudo} update-rc.d -f puma_#{application} defaults"
    end

    %w(start stop restart).each do |task|
      task task do
        run "#{sudo} service puma_#{application} #{task}"
      end
    end
  end

  after "deploy:restart", "puma:restart"
  after "deploy:start", "puma:start"
  after "deploy:stop", "puma:stop"

end