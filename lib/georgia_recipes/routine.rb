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

    %w(start stop restart).each do |task_method|
      desc "#{task_method} #{routine_name} master process"
      task task_method, roles: :app do
        run "#{sudo} service #{routine_name} #{task_method}"
      end
    end

    task :monit, roles: :app do
      destination ||= "/etc/monit/conf.d/#{routine_name}.conf"
      template "monit/routine.erb", "/tmp/monit_routine"
      run "#{sudo} mv /tmp/monit_routine #{destination}"
      run "#{sudo} chown root:root #{destination}"
      run "#{sudo} chmod 600 #{destination}"
    end

  end
end