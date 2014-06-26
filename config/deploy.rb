require 'net/ssh/gateway'

class Net::SSH::Gateway 
  # Opens a SSH tunnel from a port on a remote host to a given host and port 
  # on the local side 
  # (equivalent to openssh -R parameter) 
  def open_remote(port, host, remote_port, remote_host = "127.0.0.1") 
    ensure_open! 

    @session_mutex.synchronize do 
      @session.forward.remote(port, host, remote_port, remote_host) 
    end 

    if block_given? 
      begin 
        yield [remote_port, remote_host] 
      ensure 
        close_remote(remote_port, remote_host) 
      end 
    else 
      return [remote_port, remote_host] 
    end 
  rescue Errno::EADDRINUSE 
    retry 
  end 


  # Cancels port-forwarding over an open port that was previously opened via 
  # open_remote. 
  def close_remote(port, host = "127.0.0.1") 
    ensure_open! 

    @session_mutex.synchronize do 
      @session.forward.cancel_remote(port, host) 
    end 
  end 
end
=begin
# config valid only for Capistrano 3.1
lock '3.2.1'

set :application, 'msystem'
set :repo_url, 'git@github.com:kmi9work/mediaAnalyse.git'

set :deploy_to, '/home/web/public_html/msystem'

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
set :pty, true

# Default value for :linked_files is []
# set :linked_files, %w{config/database.yml}

# Default value for linked_dirs is []
# set :linked_dirs, %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}

# Default value for default_env is {}
# set :default_env, { path: "/usr/local/rvm/gems/ruby-2.1.2/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5

set :user, 'root'
# set :rails_env, "production"
set :deploy_via, :copy

# 
=end


server "vps45162.vps.tech-logol.ru", :app, :web, :db, :primary => true


namespace :deploy do
  task :remote_tunnel do
    gateway = Net::SSH::Gateway.new(
      'vps45162.vps.tech-logol.ru'
    )
    port = gateway.open('127.0.0.1', 9150, 9150)    
  end
end

task :hello do

end


# before "deploy:update_code", "deploy:remote_tunnel"

before "hello", "deploy:remote_tunnel"

