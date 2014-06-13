Capistrano::Configuration.instance.load do

  namespace :chef do

    task :install, roles: :app do
      run "wget -O- https://opscode.com/chef/install.sh | sudo bash"
    end

  end
end