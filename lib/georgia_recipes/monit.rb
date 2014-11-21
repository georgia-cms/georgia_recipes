Capistrano::Configuration.instance.load do

  set_default(:monit_mail_server) { ask("What is the monit mail server?")}
  set_default(:monit_email_from) { ask("Which email address should monit send emails from: ") }
  set_default(:monit_email_to) { ask("Which email address should monit send emails to: ") }
  set_default(:monit_user_credentials) { ask("What are the monit user credentials - user:password - for the monit web server?") }

  namespace :monit do

    desc "Install Monit. Requires Chef (chef:install)"
    task :install, roles: :app do
      run "#{sudo} apt-get update"
      run "#{sudo} apt-get install monit"
    end

    task :config, roles: :app do
      monit_config_destination = "/etc/monit/monitrc"
      template("monitrc.erb", "/tmp/monitrc")
      run "#{sudo} mv -u /tmp/monitrc #{monit_config_destination}"
      run "#{sudo} chown root:root #{monit_config_destination}"
      run "#{sudo} chmod 600 #{monit_config_destination}"
    end
    
    %w[start stop restart syntax reload].each do |command|
      desc "Run Monit #{command} script"
      task command do
        run "#{sudo} service monit #{command}"
      end
    end
    before "deploy:stop", "monit:stop"
    after "deploy:start", "monit:start"

    desc "Setup all Monit configuration for default Rails stack"
    task :setup do
      nginx
      unicorn
      syntax
      reload
    end

    task(:nginx, roles: :web) { monit_config "nginx" }
    task(:postgresql, roles: :db) { monit_config "postgresql" }
    task(:unicorn, roles: :app) { monit_config "unicorn" }
    task(:sidekiq, roles: :app) { monit_config "sidekiq" }
    task(:solr, roles: :web) { monit_config "solr" }
    task(:mysql, roles: :web) { monit_config "mysql" }
    task(:elasticsearch, roles: :web) { monit_config "elasticsearch" }
    task(:memcached, roles: :web) { monit_config "memcached" }

    def monit_config(name, destination = nil)
      destination ||= "/etc/monit/conf.d/#{name}.conf"
      template "monit/#{name}.erb", "/tmp/monit_#{name}"
      run "#{sudo} mv /tmp/monit_#{name} #{destination}"
      run "#{sudo} chown root:root #{destination}"
      run "#{sudo} chmod 600 #{destination}"
    end

  end
end
