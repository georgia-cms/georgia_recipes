Capistrano::Configuration.instance.load do

  namespace :nginx do
    desc "Install latest stable release of nginx"
    task :install, roles: :web do
      run "#{sudo} add-apt-repository -y ppa:nginx/stable"
      run "#{sudo} apt-get -y update"
      run "#{sudo} apt-get -y install nginx"
    end

    desc "Setup nginx configuration for this application"
    task :setup, roles: :web do
      template("nginx.erb", "/tmp/nginx_conf")
      run "#{sudo} mv -u /tmp/nginx_conf /etc/nginx/sites-available/#{application}"
      run "#{sudo} ln -sf /etc/nginx/sites-available/#{application} /etc/nginx/sites-enabled/#{application}"
      run "#{sudo} rm -f /etc/nginx/sites-enabled/default"
      restart
    end

    %w[start stop restart].each do |command|
      desc "#{command} nginx"
      task command, roles: :web do
        run "#{sudo} service nginx #{command}"
      end
    end
  end

end