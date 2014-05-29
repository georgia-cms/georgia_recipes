Capistrano::Configuration.instance.load do

  namespace :ckeditor do
    desc 'copy ckeditor nondigest assets'
    task :copy_nondigest_assets, roles: :app do
      run "cd #{latest_release} && #{rake} RAILS_ENV=#{rails_env} ckeditor:create_nondigest_assets"
    end
    after 'deploy:assets:precompile', 'ckeditor:copy_nondigest_assets'
  end

end