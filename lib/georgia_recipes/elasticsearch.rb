Capistrano::Configuration.instance.load do

  set_default :es_version, "0.90.11"

  namespace :elasticsearch do
    desc "Install latest stable release of elasticsearch"
    task :install, roles: :web do
      run "wget https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-#{es_version}.deb"
      run "#{sudo} dpkg -i elasticsearch-#{es_version}.deb"
      run "rm elasticsearch-#{es_version}.deb"
    end

    %w[start stop restart force_reload status].each do |command|
      desc "#{command} elasticsearch"
      task command, roles: :web do
        run "#{sudo} service elasticsearch #{command}"
      end
    end
  end

end