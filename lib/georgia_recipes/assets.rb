Capistrano::Configuration.instance.load do

  def precompile_assets
    run_locally "bundle exec rake assets:precompile"
    find_servers_for_task(current_task).each do |server|
      run_locally "rsync -vr --exclude='.DS_Store' -e 'ssh -p #{ssh_options[:port] || 22}' public/assets #{user}@#{server.host}:#{shared_path}/"
    end
    run_locally "rm -Rf public/assets"
  end

  namespace :deploy do
    namespace :assets do
      desc "Precompile assets on local machine and upload them to the server if assets changed."
      task :precompile, roles: :web, except: {no_release: true} do
        begin
          from = source.next_revision(current_revision)
          if capture("cd #{latest_release} && #{source.local.log(from)} vendor/assets/ app/assets/ | wc -l").to_i > 0
            precompile_assets
          else
            logger.info "Skipping asset pre-compilation because there were no asset changes"
          end
        rescue
          precompile_assets
        end
      end
    end
  end

  namespace :assets do
    desc "Compile assets on local machine and upload them to the server."
    task :compile, roles: :web, except: {no_release: true} do
      precompile_assets
    end
  end

end