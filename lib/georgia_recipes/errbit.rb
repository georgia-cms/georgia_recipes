Capistrano::Configuration.instance.load do

  def username
    @username ||= run_locally("git config user.email")
    @username[0..-2] #strips the \n from stdout
  end

  def revision
    @revision ||= run_locally('git rev-parse --short HEAD')
    @revision[0..-2] #strips the \n from stdout
  end

  unless exists? :stage
    set(:stage) { 'production' }
  end

  namespace :errbit do
    desc "Notifiy Errbit of a new deploy"
    task :notify, roles: :app do
      run "cd #{current_path} && bundle exec rake airbrake:deploy TO=#{stage} USER=#{username} REPO=#{repository} REVISION=#{revision} RAILS_ENV=#{rails_env}"
    end
    after "deploy", "errbit:notify"
  end

end