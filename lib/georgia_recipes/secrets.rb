Capistrano::Configuration.instance.load do

  namespace :secrets do

    desc "Generate the .env configuration file."
    task :setup, roles: :app do
      run "mkdir -p #{shared_path}/config"
      template "secrets.yml.erb", "#{shared_path}/config/.env"
    end

    desc "Symlink the .env file into latest release"
    task :symlink, roles: :app do
      run "ln -nfs #{shared_path}/config/.env #{release_path}/.env"
    end
    after "deploy:finalize_update", "secrets:symlink"

  end

  def generate_secret_token
    o = [('a'..'z'), ('A'..'Z'), (0..9)].map { |i| i.to_a }.flatten
    (0...128).map { o[rand(o.length)] }.join
  end

end