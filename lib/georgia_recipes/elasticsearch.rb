require 'georgia_recipes/java'
Capistrano::Configuration.instance.load do

  set_default :es_version, "1.4.1"

  namespace :elasticsearch do
    desc "Install latest stable release of elasticsearch"
    task :install, roles: :web do
      java.install
      run "wget https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-#{es_version}.deb"
      run_with_input "#{sudo} dpkg -i elasticsearch-#{es_version}.deb", /elasticsearch.yml/, 'Y'
      run "rm elasticsearch-#{es_version}.deb"
      elasticsearch.setup
      elasticsearch.plugins.install
      elasticsearch.restart
    end

    desc "Setup elasticsearch to run on startup"
    task :setup, roles: :web do
      run "#{sudo} update-rc.d elasticsearch defaults 95 10"
    end

    namespace :plugins do
      task :install, roles: :web do
        run "cd /usr/share/elasticsearch && sudo bin/plugin -i elasticsearch/marvel/latest"
        run "cd /usr/share/elasticsearch && sudo bin/plugin -i karmi/elasticsearch-paramedic"
      end
    end

    %w[start stop restart force_reload status].each do |command|
      desc "#{command} elasticsearch"
      task command, roles: :web do
        run "#{sudo} service elasticsearch #{command}"
      end
    end
  end

end