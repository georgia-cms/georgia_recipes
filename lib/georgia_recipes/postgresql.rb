Capistrano::Configuration.instance.load do

  set_default(:db_host, "localhost")
  set_default(:db_user) { (app_var rescue application) }
  set_default(:db_password) { Capistrano::CLI.password_prompt "PostgreSQL Password: " }
  set_default(:db_database) { "#{db_user}_production" }
  set_default(:postgresql_pid) { "/var/run/postgresql/9.1-main.pid" }

  namespace :pg do

    desc "Install the latest stable release of PostgreSQL."
    task :install, roles: :db, only: {primary: true} do
      run "#{sudo} add-apt-repository -y ppa:pitti/postgresql"
      run "#{sudo} apt-get -y update"
      run "#{sudo} apt-get -y install postgresql libpq-dev"
    end

    desc "Generate the database.yml configuration file."
    task :setup, roles: :app do
      run "mkdir -p #{shared_path}/config"
      template "postgresql.yml.erb", "#{shared_path}/config/database.yml"
      create_user
      create_db
    end

    desc "Drop & Create database"
    task :reset, roles: :db do
      if are_you_sure?
        deploy.stop
        run %Q{#{sudo} -u postgres psql -c "drop database #{db_database};"}
        create_db
        deploy.start
      end
    end

    desc "Symlink the database.yml file into latest release"
    task :symlink, roles: :app do
      run "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml"
    end
    after "deploy:finalize_update", "pg:symlink"

    desc "Pull database from remote server"
    task :pull, roles: :db do
      run "mkdir -p #{shared_path}/backups"
      run %Q{#{sudo} -u postgres pg_dump #{db_database} --format=tar > #{shared_path}/backups/#{database_filename}}
      get "#{shared_path}/backups/#{database_filename}", "/tmp/#{database_filename}"
      run "rm #{shared_path}/backups/#{database_filename}"
      run_locally "#{sudo} -u postgres pg_restore /tmp/#{database_filename} --clean --format=tar --dbname=#{db_user}_development"
      run_locally "rm /tmp/#{database_filename}"
    end

    desc "Push database to remote server"
    task :push, roles: :db do
      if are_you_sure?
        run_locally %Q{#{sudo} -u postgres pg_dump #{db_user}_development --format=tar > /tmp/#{database_filename}}
        upload "/tmp/#{database_filename}", "/tmp/#{database_filename}"
        run_locally "rm /tmp/#{database_filename}"
        run "#{sudo} -u postgres pg_restore /tmp/#{database_filename} --clean --format=tar --dbname=#{db_database}"
        run "rm /tmp/#{database_filename}"
        deploy.restart
      end
    end

    desc "Seed database with db/seeds.rb"
    task :seed do
      run "cd #{current_path} && bundle exec rake db:seed RAILS_ENV=#{rails_env}"
    end

    ### Helpers

    def database_filename
      @database_filename ||= "#{db_user}_#{timestamp}.sql"
    end

    def database_table_filename
      @database_table_filename ||= "#{db_user}_#{table_name}_#{timestamp}.sql"
    end

    def table_name
      @table_name ||= Capistrano::CLI.ui.ask "Which remote database table would you like to pull?"
    end

    def create_user
      run %Q{#{sudo} -u postgres psql -c "create user #{db_user} with password '#{db_password}';"}
    end

    def create_db
      run %Q{#{sudo} -u postgres psql -c "create database #{db_database} owner #{db_user} ENCODING = 'UTF-8' LC_COLLATE = 'en_US.UTF-8' LC_CTYPE = 'en_US.UTF-8' TEMPLATE template0;"}
    end
  end

end