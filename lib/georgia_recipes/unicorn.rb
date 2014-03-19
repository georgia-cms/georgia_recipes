Capistrano::Configuration.instance.load do

  set_default(:unicorn_user) { user }
  set_default(:unicorn_pid) { "#{current_path}/tmp/pids/unicorn.pid" }
  set_default(:unicorn_config) { "#{shared_path}/config/unicorn.rb" }
  set_default(:unicorn_log) { "#{shared_path}/log/unicorn.log" }

  def remote_file_exists?(full_path)
    'true' ==  capture("if [ -e #{full_path} ]; then echo 'true'; fi").strip
  end

  def remote_process_exists?(pid_file)
    capture("ps -p $(cat #{pid_file}) ; true").strip.split("\n").size == 2
  end

  def unicorn_get_pid(pid_file=unicorn_pid)
    if remote_file_exists?(pid_file) && remote_process_exists?(pid_file)
      capture("cat #{pid_file}")
    end
  end

  def unicorn_get_oldbin_pid
    oldbin_pid_file = "#{unicorn_pid}.oldbin"
    unicorn_get_pid(oldbin_pid_file)
  end

  def unicorn_send_signal(pid, signal)
    run "#{try_sudo} kill -s #{signal} #{pid}"
  end

  def unicorn_workers
    @unicorn_workers ||= Capistrano::CLI.ui.ask("How many unicorn workers?")
  end

  before [ 'unicorn:start', 'unicorn:stop', 'unicorn:shutdown', 'unicorn:restart', 'unicorn:reload', 'unicorn:add_worker', 'unicorn:remove_worker' ] do
    _cset(:unicorn_pid) { "#{fetch(:current_path)}/tmp/pids/unicorn.pid" }
    _cset(:app_env) { (fetch(:rails_env) rescue 'production') }
    _cset(:unicorn_env) { fetch(:app_env) }
    _cset(:unicorn_bin, "unicorn")
  end

  namespace :unicorn do

    desc "Setup Unicorn initializer and app configuration"
    task :setup, roles: :app do
      run "mkdir -p #{shared_path}/config"
      template "unicorn.rb.erb", unicorn_config
      template "unicorn_init.erb", "/tmp/unicorn_init"
      run "chmod +x /tmp/unicorn_init"
      run "#{sudo} mv /tmp/unicorn_init /etc/init.d/unicorn_#{application}"
      run "#{sudo} update-rc.d -f unicorn_#{application} defaults"
    end

    desc 'Start Unicorn master process'
    task :start, :roles => :app, :except => {:no_release => true} do
      if remote_file_exists?(unicorn_pid)
        if remote_process_exists?(unicorn_pid)
          logger.important("Unicorn is already running!", "Unicorn")
          next
        else
          run "rm #{unicorn_pid}"
        end
      end

      primary_config_path = "#{shared_path}/config/unicorn.rb"
      if remote_file_exists?(primary_config_path)
        config_path = primary_config_path
      else
        config_path = "#{current_path}/config/unicorn/#{unicorn_env}.rb"
      end

      if remote_file_exists?(config_path)
        logger.important("Starting...", "Unicorn")
        run "cd #{current_path} && BUNDLE_GEMFILE=#{current_path}/Gemfile bundle exec #{unicorn_bin} -c #{config_path} -E #{app_env} -D"
      else
        logger.important("Config file for \"#{unicorn_env}\" environment was not found at \"#{config_path}\"", "Unicorn")
      end
    end

    desc 'Stop Unicorn'
    task :stop, :roles => :app, :except => {:no_release => true} do
      pid = unicorn_get_pid
      unless pid.nil?
        logger.important("Stopping...", "Unicorn")
        unicorn_send_signal(pid, "QUIT")
      else
        logger.important("Unicorn is not running.", "Unicorn")
      end
    end

    desc 'Immediately shutdown Unicorn'
    task :shutdown, :roles => :app, :except => {:no_release => true} do
      pid = unicorn_get_pid
      unless pid.nil?
        logger.important("Stopping...", "Unicorn")
        unicorn_send_signal(pid, "TERM")
      else
        logger.important("Unicorn is not running.", "Unicorn")
      end
    end

    desc 'Restart Unicorn'
    task :restart, :roles => :app, :except => {:no_release => true} do
      pid = unicorn_get_pid
      unless pid.nil?
        logger.important("Restarting...", "Unicorn")
        unicorn_send_signal(pid, 'USR2')
        newpid = unicorn_get_pid
        oldpid = unicorn_get_oldbin_pid
        unless oldpid.nil?
          logger.important("Quiting old master...", "Unicorn")
          unicorn_send_signal(oldpid, 'QUIT')
        end
      else
        unicorn.start
      end
    end

    desc 'Reload Unicorn'
    task :reload, :roles => :app, :except => {:no_release => true} do
      pid = unicorn_get_pid
      unless pid.nil?
        logger.important("Reloading...", "Unicorn")
        unicorn_send_signal(pid, 'HUP')
      else
        unicorn.start
      end
    end

    desc 'Add a new worker'
    task :add_worker, :roles => :app, :except => {:no_release => true} do
      pid = unicorn_get_pid
      unless pid.nil?
        logger.important("Adding a new worker...", "Unicorn")
        unicorn_send_signal(pid, "TTIN")
      else
        logger.important("Server is not running.", "Unicorn")
      end
    end

    desc 'Remove amount of workers'
    task :remove_worker, :roles => :app, :except => {:no_release => true} do
      pid = unicorn_get_pid
      unless pid.nil?
        logger.important("Removing worker...", "Unicorn")
        unicorn_send_signal(pid, "TTOU")
      else
        logger.important("Server is not running.", "Unicorn")
      end
    end
  end
  after "deploy:restart", "unicorn:restart"
  after "deploy:start", "unicorn:start"
  after "deploy:stop", "unicorn:stop"

end