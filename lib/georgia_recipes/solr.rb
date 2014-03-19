Capistrano::Configuration.instance.load do

  namespace :solr do

    desc "Install Solr"
    task :install, roles: :app do
      run "mkdir -p cookbooks"
      git_pull_or_clone('cookbooks/hipsnip-solr', 'git@github.com:hipsnip-cookbooks/solr.git')
      git_pull_or_clone('cookbooks/hipsnip-jetty', 'git@github.com:hipsnip-cookbooks/jetty.git')
      git_pull_or_clone('cookbooks/java', 'git@github.com:opscode-cookbooks/java.git')
      git_pull_or_clone('cookbooks/aws', 'git@github.com:opscode-cookbooks/aws.git')
      git_pull_or_clone('cookbooks/windows', 'git@github.com:opscode-cookbooks/windows.git')
      git_pull_or_clone('cookbooks/powershell', 'git@github.com:opscode-cookbooks/powershell.git')
      git_pull_or_clone('cookbooks/chef_handler', 'git@github.com:opscode-cookbooks/chef_handler.git')
      template "solr.chef.node.json.erb", "node.json"
      template "chef-solo.rb.erb", "solo.rb"
      run "#{sudo} chef-solo -j ~/node.json -c ~/solo.rb"
    end

    # Run once you have a config a solr config for your application
    task :config, roles: :app do
      run "#{sudo} cp -R #{current_path}/solr/conf /usr/share/solr/"
    end

    task :setup, roles: :app do
      run "#{sudo} chown jetty:jetty -R #{shared_path}/solr/data"
      run "#{sudo} chmod +w #{shared_path}/solr/data"
    end

    task :uninstall, roles: :app do
      solr.stop
      run "#{sudo} update-rc.d -f jetty remove"
    end

    desc "Start Solr"
    task :start, roles: :app do
      run "#{sudo} service jetty start"
    end

    desc "Stop Solr"
    task :stop, roles: :app do
      run "#{sudo} service jetty stop"
    end

    desc "Restart Solr"
    task :restart, roles: :app do
      solr.stop
      solr.start
    end

    namespace :reindex do

      desc "Reindex the whole database"
      task :all, :roles => :app do
        run_with_input "cd #{current_path} && RAILS_ENV=#{rails_env} bundle exec rake sunspot:reindex", /^Are you sure/, 'y'
      end

      desc 'Reindex messages on solr'
      task :messages, :roles => :app do
        run "cd #{current_path} && bundle exec rake solr:messages:reindex RAILS_ENV=#{rails_env}"
      end

      desc 'Reindex assets on solr'
      task :assets, :roles => :app do
        run "cd #{current_path} && bundle exec rake solr:assets:reindex RAILS_ENV=#{rails_env}"
      end

      desc 'Reindex pages on solr'
      task :pages, :roles => :app do
        run "cd #{current_path} && bundle exec rake solr:pages:reindex RAILS_ENV=#{rails_env}"
      end

    end

  end

end