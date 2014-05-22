def ubuntu_release
  @ubuntu_release ||= capture("lsb_release -r | awk '{ print $2 }'")
end

def timestamp
  @timestamp ||= Time.now.strftime('%Y%m%d%H%M%S')
end

def template(from, to)
  erb = File.read(File.expand_path("../templates/#{from}", __FILE__))
  put ERB.new(erb).result(binding), to
end

def set_default(name, *args, &block)
  set(name, *args, &block) unless exists?(name)
end

def are_you_sure?
  ask("Holy Moly! Are you sure you want to do that? (type 'yes' if so)") == 'yes'
end

def ask question
  Capistrano::CLI.ui.ask question
end

# Methods taken from: https://github.com/donnoman/cap-recipes/blob/master/lib/cap_recipes/tasks/utilities.rb

##
# Run a command and ask for input when input_query is seen.
# Sends the response back to the server.
#
# +input_query+ is a regular expression that defaults to /^Password/.
# Can be used where +run+ would otherwise be used.
# run_with_input 'ssh-keygen ...', /^Are you sure you want to overwrite\?/
def run_with_input(shell_command, input_query=/^Password/, response=nil)
  handle_command_with_input(:run, shell_command, input_query, response)
end

##
# Does the actual capturing of the input and streaming of the output.
#
# local_run_method: run or sudo
# shell_command: The command to run
# input_query: A regular expression matching a request for input: /^Please enter your password/
def handle_command_with_input(local_run_method, shell_command, input_query, response=nil)
  send(local_run_method, shell_command, {:pty => true}) do |channel, stream, data|
    if data =~ input_query
      if response
        logger.info "#{data} #{"*"*(rand(10)+5)}", channel[:host]
        channel.send_data "#{response}\n"
      else
        logger.info data, channel[:host]
        response = ::Capistrano::CLI.password_prompt "#{data}"
        channel.send_data "#{response}\n"
      end
    else
      logger.info data, channel[:host]
    end
  end
end

def git_pull_or_clone repo_name, repo_url
  run "bash -c 'if cd #{repo_name}; then git pull origin master; else git clone #{repo_url} #{repo_name}; fi'"
end

# run a command on the server with a different user
def with_user(new_user, new_pass, &block)
  old_user = user
  old_pass = (exists?(password) ? password : '')
  set_user(new_user, new_pass)
  begin
    yield
  rescue Exception => e
    set_user(old_user, old_pass)
    raise e
  end
  set_user(old_user, old_pass)
end

# change the capistrano user
def set_user(user, pass)
  set :user, user
  set :password, pass
  close_sessions
end

# disconnect all sessions
def close_sessions
  sessions.values.each { |session| session.close }
  sessions.clear
end