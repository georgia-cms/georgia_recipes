Capistrano::Configuration.instance.load do
  namespace :monit do

    desc "Install Monit. Requires Chef (chef:install)"
    task :install, roles: :app do
      run "#{sudo} apt-get update"
      run "#{sudo} apt-get install monit"
    end

    task :config, roles: :app do
      template "monit.node.json.erb", "node.json"
      template "chef-solo.rb.erb", "solo.rb"
      run "#{sudo} chef-solo -j node.json -c solo.rb"
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
      postgresql
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

    def monit_config(name, destination = nil)
      destination ||= "/etc/monit/conf.d/#{name}.conf"
      template "monit/#{name}.erb", "/tmp/monit_#{name}"
      run "#{sudo} mv /tmp/monit_#{name} #{destination}"
      run "#{sudo} chown root:root #{destination}"
      run "#{sudo} chmod 600 #{destination}"
    end

  end
end