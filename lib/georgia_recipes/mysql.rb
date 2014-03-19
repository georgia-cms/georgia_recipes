Capistrano::Configuration.instance.load do

  require 'yaml'

  namespace :mysql do

    desc "Install MySQL"
    task :install, roles: :app do
      run "#{sudo} apt-get -y update"
      run "#{sudo} apt-get -y install mysql-server mysql-server-5.5 mysql-client-5.5 libmysqlclient18 libmysqlclient-dev mysql-common"
    end
    after "deploy:install", "mysql:install"

    desc "create a new mysql database and user"
    task :setup, roles: :app do
     sql = <<-SQL
      CREATE DATABASE #{remote_db_name};
      GRANT ALL PRIVILEGES ON #{remote_db_name}.* TO #{db_user}@localhost IDENTIFIED BY '#{remote_db_password}';
      SQL

      run "mysql --user=root -p --execute=\"#{sql}\"" do |channel, stream, data|
        if data =~ /^Enter password:/
          pass = Capistrano::CLI.password_prompt "Enter database password for root:"
          channel.send_data "#{pass}\n"
        end
      end
    end
    after "deploy:setup", "db:setup"

    desc "Pull mysql database dump from remote server. remote => local"
    task :pull, roles: :db do
      run "mkdir -p #{shared_path}/backups"
      run %Q{mysqldump -u #{remote_db_user} --password=#{remote_db_password} #{remote_db_name} > #{shared_path}/backups/#{database_filename}}
      get "#{shared_path}/backups/#{database_filename}", "/tmp/#{database_filename}"
      run "rm #{shared_path}/backups/#{database_filename}"
      run_locally "mysql -u #{local_db_user} --password=#{local_db_password} #{local_db_name} < /tmp/#{database_filename}"
      run_locally "rm /tmp/#{database_filename}"
    end

    desc "Push mysql database dump to remote server. local => remote"
    task :push, roles: :db do
      if are_you_sure?
        run_locally %Q{mysqldump -u #{local_db_user} --password=#{local_db_password} #{local_db_name} > /tmp/#{database_filename}}
        upload "/tmp/#{database_filename}", "/tmp/#{database_filename}"
        run_locally "rm /tmp/#{database_filename}"
        run "mysql -u #{remote_db_user} --password=#{remote_db_password} #{remote_db_name} < /tmp/#{database_filename}"
        run "rm /tmp/#{database_filename}"
      end
    end

    desc "Restart mysql"
    task :restart, roles: :db do
      run "sudo service mysql restart"
    end

    def database_filename
      @database_filename ||= "#{application}_#{timestamp}.sql"
    end

  end

end