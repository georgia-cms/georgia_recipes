Capistrano::Configuration.instance.load do

  namespace :mongodb do

    desc "Install MongoDB"
    task :install, roles: :app do
      run "#{sudo} apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10"
      run "echo 'deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen' | #{sudo} tee /etc/apt/sources.list.d/mongodb.list"
      run "#{sudo} apt-get -y update"
      run "#{sudo} apt-get -y install mongodb-10gen"
    end

  end

end