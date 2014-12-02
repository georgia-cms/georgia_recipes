Capistrano::Configuration.instance.load do

  namespace :java do

    task :install, roles: :web do
      run "#{sudo} apt-get update"
      run "#{sudo} apt-get purge -y openjdk-\* icedtea-\* icedtea6-\*"
      run "#{sudo} apt-get install -y openjdk-7-jre"
      run "JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64"
      run "export JAVA_HOME"
    end

  end

end