Capistrano::Configuration.instance.load do

  set_default(:puma_user) { user }
  set_default(:puma_pid) { "#{shared_path}/pids/puma.pid" }
  set_default(:puma_state) { "#{shared_path}/pids/puma.state" }
  set_default(:puma_config) { "#{shared_path}/config/puma.rb" }
  set_default(:puma_log) { "#{shared_path}/log/puma.log" }
  set_default(:puma_stdout_log) { "#{shared_path}/log/puma-#{rails_env}.stdout.log" }
  set_default(:puma_stderr_log) { "#{shared_path}/log/puma-#{rails_env}.stderr.log" }

  def remote_file_exists?(full_path)
    'true' ==  capture("if [ -e #{full_path} ]; then echo 'true'; fi").strip
  end

  def remote_process_exists?(pid_file)
    capture("ps -p $(cat #{pid_file}) ; true").strip.split("\n").size == 2
  end

  def puma_get_pid(pid_file=puma_pid)
    if remote_file_exists?(pid_file) && remote_process_exists?(pid_file)
      capture("cat #{pid_file}")
    end
  end

  def puma_get_oldbin_pid
    oldbin_pid_file = "#{puma_pid}.oldbin"
    puma_get_pid(oldbin_pid_file)
  end

  def puma_send_signal(pid, signal)
    run "#{try_sudo} kill -s #{signal} #{pid}"
  end

  def puma_workers
    @puma_workers ||= Capistrano::CLI.ui.ask("How many puma workers?")
  end

  before [ 'puma:start', 'puma:stop', 'puma:shutdown', 'puma:restart', 'puma:reload', 'puma:add_worker', 'puma:remove_worker' ] do
    _cset(:puma_pid) { "#{fetch(:shared_path)}/pids/puma.pid" }
    _cset(:app_env) { (fetch(:rails_env) rescue 'production') }
    _cset(:puma_env) { fetch(:app_env) }
    _cset(:puma_bin, "puma")
  end

  namespace :puma do

    desc "Setup puma initializer and app configuration"
    task :setup, roles: :app do
      run "mkdir -p #{shared_path}/config"
      template "puma.rb.erb", puma_config
    end

    desc 'Start puma master process'
    task :start, :roles => :app, :except => {:no_release => true} do
      if remote_file_exists?(puma_pid)
        if remote_process_exists?(puma_pid)
          logger.important("puma is already running!", "puma")
          next
        else
          run "#{sudo} rm #{puma_pid}"
        end
      end

      primary_config_path = "#{shared_path}/config/puma.rb"
      if remote_file_exists?(primary_config_path)
        config_path = primary_config_path
      else
        config_path = "#{current_path}/config/puma/#{puma_env}.rb"
      end

      if remote_file_exists?(config_path)
        logger.important("Starting...", "puma")
        run "cd #{current_path} && BUNDLE_GEMFILE=#{current_path}/Gemfile RAILS_ENV=#{rails_env} bundle exec #{puma_bin} -C #{config_path}"
      else
        logger.important("Config file for \"#{puma_env}\" environment was not found at \"#{config_path}\"", "puma")
      end
    end

    desc 'Stop puma'
    task :stop, :roles => :app, :except => {:no_release => true} do
      pid = puma_get_pid
      unless pid.nil?
        logger.important("Stopping...", "puma")
        puma_send_signal(pid, "QUIT")
      else
        logger.important("puma is not running.", "puma")
      end
    end

    desc 'Immediately shutdown puma'
    task :shutdown, :roles => :app, :except => {:no_release => true} do
      pid = puma_get_pid
      unless pid.nil?
        logger.important("Stopping...", "puma")
        puma_send_signal(pid, "TERM")
      else
        logger.important("puma is not running.", "puma")
      end
    end

    desc 'Restart puma'
    task :restart, :roles => :app, :except => {:no_release => true} do
      pid = puma_get_pid
      unless pid.nil?
        logger.important("Restarting...", "puma")
        puma_send_signal(pid, 'USR2')
        newpid = puma_get_pid
        oldpid = puma_get_oldbin_pid
        unless oldpid.nil?
          logger.important("Quiting old master...", "puma")
          puma_send_signal(oldpid, 'QUIT')
        end
      else
        puma.start
      end
    end

    desc 'Reload puma'
    task :reload, :roles => :app, :except => {:no_release => true} do
      pid = puma_get_pid
      unless pid.nil?
        logger.important("Reloading...", "puma")
        puma_send_signal(pid, 'HUP')
      else
        puma.start
      end
    end

    desc 'Add a new worker'
    task :add_worker, :roles => :app, :except => {:no_release => true} do
      pid = puma_get_pid
      unless pid.nil?
        logger.important("Adding a new worker...", "puma")
        puma_send_signal(pid, "TTIN")
      else
        logger.important("Server is not running.", "puma")
      end
    end

    desc 'Remove amount of workers'
    task :remove_worker, :roles => :app, :except => {:no_release => true} do
      pid = puma_get_pid
      unless pid.nil?
        logger.important("Removing worker...", "puma")
        puma_send_signal(pid, "TTOU")
      else
        logger.important("Server is not running.", "puma")
      end
    end
  end
  after "deploy:restart", "puma:restart"
  after "deploy:start", "puma:start"
  after "deploy:stop", "puma:stop"

end