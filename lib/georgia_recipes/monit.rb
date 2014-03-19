Capistrano::Configuration.instance.load do
  namespace :monit do

    desc "Install Monit. Requires Chef (chef:install)"
    task :install, roles: :app do
      run "mkdir -p cookbooks"
      git_pull_or_clone('cookbooks/yum', 'git@github.com:opscode-cookbooks/yum.git')
      git_pull_or_clone('cookbooks/sysctl', 'git@github.com:rcbops-cookbooks/sysctl.git')
      git_pull_or_clone('cookbooks/apt', 'git@github.com:opscode-cookbooks/apt.git')
      git_pull_or_clone('cookbooks/osops-utils', 'git@github.com:rcbops-cookbooks/osops-utils.git')
      git_pull_or_clone('cookbooks/monit', 'git@github.com:rcbops-cookbooks/monit.git')
      config
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
      sidekiq
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