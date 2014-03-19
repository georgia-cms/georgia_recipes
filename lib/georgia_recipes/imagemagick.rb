Capistrano::Configuration.instance.load do

  namespace :imagemagick do
    desc "Install ImageMagick dependencies"
    task :install, roles: :web do
      run "#{sudo} apt-get -y install imagemagick libmagickcore-dev libmagickwand-dev"
    end
  end

end