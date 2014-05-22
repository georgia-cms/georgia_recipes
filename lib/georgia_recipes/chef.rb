Capistrano::Configuration.instance.load do

  namespace :chef do

    task :install, roles: :app do
      run "gem install chef --no-ri --no-rdoc"
    end

  end
end