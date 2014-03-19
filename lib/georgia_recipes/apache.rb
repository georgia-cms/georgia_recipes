Capistrano::Configuration.instance.load do

  namespace :apache do
    desc "Install Apache2"
    task :install, roles: :web do
      run "#{sudo} apt-get -y install apache2 apache2-prefork-dev libapr1-dev libaprutil1-dev libapache2-mod-php5"
    end
  end

end