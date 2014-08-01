require 'capistrano'
require 'capistrano/cli'
require 'georgia_recipes/helper_methods'

Capistrano::Configuration.instance.load do

  set_default(:host) { ask("What is the fully qualified domain name?") }

  namespace :base do
    task :install do
      run "#{sudo} apt-get update"
      run "#{sudo} apt-get -y install vim python-software-properties software-properties-common subversion libxslt1-dev libxml2-dev git-core"
      run "ssh-keyscan github.com >> ~/.ssh/known_hosts"
    end
  end

  namespace :deploy do

    desc "Adds user 'deployer' with your ssh keys"
    task :bootstrap do
      with_user('root', password) do
        run "adduser --disabled-password --gecos '' deployer"
        run "echo 'deployer ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers"
        run "apt-get update ; apt-get -y install curl"
        update_keys
      end
    end
  end

  namespace :ssh do
    task :reset_keys do
      with_user('root', password) do
        update_keys
      end
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
    ask "Which Github handle would you like to add?"
  end

  def update_keys
    run "sudo -u deployer curl https://github.com/#{github_handle}.keys -o /home/deployer/.ssh/authorized_keys --create-dirs"
  end

end