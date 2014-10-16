Capistrano::Configuration.instance.load do

  set_default(:routine_name) { raise 'Need to set routine_name variable in your config/deploy.rb' }

  namespace routine_name do

    set_default(:routine_user) { user }
    set_default(:routine_pid) { "#{shared_path}/pids/#{routine_name}.pid" }
    set_default(:routine_log) { "#{shared_path}/log/#{routine_name}.log" }
    set_default(:routine_bin) { "#{current_path}/bin/#{routine_name} -Ilib -d --log #{routine_log} --pid #{routine_pid}" }

    desc "Setup a routine service"
    task :setup, roles: :app do
      template "routine_init.erb.sh", "/tmp/#{routine_name}_init"
      run "chmod +x /tmp/#{routine_name}_init"
      run "#{sudo} mv /tmp/#{routine_name}_init /etc/init.d/#{routine_name}"
      run "#{sudo} update-rc.d -f #{routine_name} defaults"
    end

    desc "Start #{routine_name} master process"
    task :start, :roles => :app, :except => {:no_release => true} do
      run "cd #{current_path} && RAILS_ENV=#{rails_env} bundle exec #{routine_bin}"
    end

    desc "Stop #{routine_name}"
    task :stop, :roles => :app, :except => {:no_release => true} do
      run "#{sudo} kill -KILL $(cat #{routine_pid})"
    end

    desc "Restart #{routine_name}"
    task :restart, :roles => :app, :except => {:no_release => true} do
      stop
      start
    end

    desc "Shutdown #{routine_name}"
    task :shutdown, :roles => :app, :except => {:no_release => true} do
      run "#{sudo} service #{routine_name} force-stop"
    end

    task :monit, roles: :app do
      destination ||= "/etc/monit/conf.d/routine.conf"
      template "monit/routine.erb", "/tmp/monit_routine"
      run "#{sudo} mv /tmp/monit_routine #{destination}"
      run "#{sudo} chown root:root #{destination}"
      run "#{sudo} chmod 600 #{destination}"
    end

  end
end