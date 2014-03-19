Capistrano::Configuration.instance.load do

  namespace :chef do

    task :install, roles: :app do
      run "curl -L https://www.opscode.com/chef/install.sh | sudo bash"
    end

  end
end