Capistrano::Configuration.instance.load do

  # These tasks are meant to be use if you keep Carrierwave files locally
  #   instead of a Cloud Storage (Amazon S3, Rackspace Cloud Files, etc.)
  namespace :carrierwave do

    desc "Symlink public/uploads folder to shared files directories"
    task :symlink, except: { no_release: true } do
      run "rm -rf #{current_path}/public/uploads"
      run "mkdir -p #{shared_path}/uploads"
      run "ln -fns #{shared_path}/uploads #{current_path}/public/uploads"
    end
    after 'deploy:create_symlink', 'carrierwave:symlink'

    namespace :uploads do

      desc "Zip and pull all files from the public/uploads folder. remote => local"
      task :pull, roles: :app do
        run "cd #{shared_path} && tar -czvf /tmp/uploads_#{timestamp}.tar.gz uploads"
        get "/tmp/uploads_#{timestamp}.tar.gz", "/tmp/uploads_#{timestamp}.tar.gz"
        run "rm /tmp/uploads_#{timestamp}.tar.gz"
        run_locally "cd public && tar -xzvf /tmp/uploads_#{timestamp}.tar.gz"
        run_locally "rm /tmp/uploads_#{timestamp}.tar.gz"
      end

      desc "Zip and push all files to the public/uploads folder. local => remote"
      task :push, roles: :app do
        run_locally "cd public && tar -czvf /tmp/uploads_#{timestamp}.tar.gz uploads"
        upload "/tmp/uploads_#{timestamp}.tar.gz", "/tmp/uploads_#{timestamp}.tar.gz"
        run_locally "rm /tmp/uploads_#{timestamp}.tar.gz"
        run "cd #{shared_path} && tar -xzvf /tmp/uploads_#{timestamp}.tar.gz"
        run "rm /tmp/uploads_#{timestamp}.tar.gz"
      end

    end

  end

end