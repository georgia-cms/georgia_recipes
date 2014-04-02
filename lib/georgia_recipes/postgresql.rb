Capistrano::Configuration.instance.load do

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
      run %Q{#{sudo} -u postgres pg_dump #{remote_db_name} --format=tar > #{shared_path}/backups/#{database_filename}}
      get "#{shared_path}/backups/#{database_filename}", "/tmp/#{database_filename}"
      run "rm #{shared_path}/backups/#{database_filename}"
      run_locally "#{sudo} -u postgres pg_restore /tmp/#{database_filename} --clean --format=tar --dbname=#{local_db_name}"
      run_locally "rm /tmp/#{database_filename}"
    end

    desc "Push database to remote server"
    task :push, roles: :db do
      if are_you_sure?
        run_locally %Q{#{sudo} -u postgres pg_dump #{local_db_user} --format=tar > /tmp/#{database_filename}}
        upload "/tmp/#{database_filename}", "/tmp/#{database_filename}"
        run_locally "rm /tmp/#{database_filename}"
        run "#{sudo} -u postgres pg_restore /tmp/#{database_filename} --clean --format=tar --dbname=#{remote_db_name}"
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
      @database_filename ||= "#{application}_#{timestamp}.sql"
    end

    def database_table_filename
      @database_table_filename ||= "#{application}_#{table_name}_#{timestamp}.sql"
    end

    def table_name
      @table_name ||= ask("Which remote database table would you like to pull?")
    end

    def create_user
      run %Q{#{sudo} -u postgres psql -c "create user #{remote_db_user} with password '#{remote_db_password}';"}
    end

    def create_db
      run %Q{#{sudo} -u postgres psql -c "create database #{remote_db_name} owner #{remote_db_user} ENCODING = 'UTF-8' LC_COLLATE = 'en_US.UTF-8' LC_CTYPE = 'en_US.UTF-8' TEMPLATE template0;"}
    end

    def local_db_config(key)
      begin
        config = File.read('config/database.yml')
        YAML.load(config)["development"][key.to_s]
      rescue
        request_from_prompt(key)
      end
    end

    def remote_db_config(key)
      begin
        config = capture("cat #{shared_path}/config/database.yml")
        YAML.load(config)[rails_env][key.to_s]
      rescue
        request_from_prompt(key, env: rails_env)
      end
    end

    def request_from_prompt key, env: 'Development'
      case key
      when :database
        ask("#{env} database name: ")
      when :password
        Capistrano::CLI.password_prompt("#{env} database password: ")
      else
        ask("#{env} database #{key}: ")
      end
    end

    set_default(:remote_db_user) { remote_db_config(:username) }
    set_default(:remote_db_name) { remote_db_config(:database) }
    set_default(:remote_db_password) { remote_db_config(:password) }

    set_default(:local_db_user) { local_db_config(:username) }
    set_default(:local_db_name) { local_db_config(:database) }
    set_default(:local_db_password) { local_db_config(:password)  }

  end

end