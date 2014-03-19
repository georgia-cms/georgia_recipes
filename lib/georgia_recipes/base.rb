require 'capistrano'
require 'capistrano/cli'

Capistrano::Configuration.instance.load do

  set_default(:host) { ask("What is the fully qualified domain name?") }
  set_default(:remote_db_user) { db_config_file["#{rails_env}"]["username"] rescue ask("Remote database user: ") }
  set_default(:remote_db_user) { db_config_file["#{rails_env}"]["database"] rescue ask("Remote database name: ") }
  set_default(:remote_db_user) { db_config_file["#{rails_env}"]["password"] rescue ask("Remote database password: ") }
  set_default(:local_db_user) { db_config_file["development"]["username"] rescue ask("Local database user: ") }
  set_default(:local_db_user) { db_config_file["development"]["database"] rescue ask("Local database name: ") }
  set_default(:local_db_user) { db_config_file["development"]["password"] rescue ask("Local database password: ") }

  namespace :deploy do

    desc "Adds user 'deployer' with your ssh keys"
    task :bootstrap do
      with_user('root') do
        run "adduser --disabled-password --gecos '' deployer"
        run "echo 'deployer ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers"
        run "apt-get update ; apt-get -y install curl"
        run "sudo -u deployer curl https://github.com/#{github_handle}.keys -o /home/deployer/.ssh/authorized_keys --create-dirs"
      end
    end
  end

  namespace :ssh do
    task :reset_keys do
      run "curl https://github.com/#{github_handle}.keys -o ~/.ssh/authorized_keys --create-dirs"
    end
    task :add_keys do
      run "sed -i -e '$a\' ~/.ssh/authorized_keys"
      run "curl https://github.com/#{github_handle}.keys | tee -a ~/.ssh/authorized_keys"
    end
  end

  namespace :locale do
    desc "Set locale to en_US.UTF-8"
    task :setup, roles: :web do
      run "#{sudo} apt-get -y install language-pack-en-base"
      run "export LANGUAGE=en_US.UTF-8"
      run "export LANG=en_US.UTF-8"
      run "export LC_ALL=en_US.UTF-8"
      run "export LC_CTYPE=en_US.UTF-8"
      run "#{sudo} locale-gen en_US.UTF-8"
      run "#{sudo} dpkg-reconfigure locales"
    end
  end

  def github_handle
    Capistrano::CLI.ui.ask "Which Github handle would you like to add?"
  end

end