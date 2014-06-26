require 'socksify'

TCPSocket.socks_server = 'localhost'
TCPSocket.socks_port = '9150'

require 'net/ssh'

def ssh_exec ssh, str
  ev = @env_vars.map{|i,j| i.to_s + "=" + j.to_s}.join(" ") + " "
  gets if @carefull
  ssh.exec!(ev + str) do |ch, stream, data|
    print "#{stream.capitalize}: "
    puts data
  end
end

HOST = 'vps45162.vps.tech-logol.ru'
USER = 'root'
PASS = 'BD3KHd4C'
git_url = 'git@github.com:kmi9work/mediaAnalyse.git'
@env_vars = {
  "RAILS_ENV" => "production",
  "PATH" => "/usr/local/jdk/bin:/usr/local/rvm/gems/ruby-2.1.2/bin:/usr/local/rvm/gems/ruby-2.1.2@global/bin:/usr/local/rvm/rubies/ruby-2.1.2/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/rvm/bin:/usr/local/bin:/usr/X11R6/bin:/root/bin"
}

remote_app_path = "/home/web/public_html/msystem"
remote_dir = "/root/msystem"
remote_backup_dir = remote_dir + "/backup"
remote_config_dir = remote_dir + "/config"
@carefull = true

puts "Git check..."
puts system 'git status'
puts "Do you need to commit changes? (y/n)"

if (ch = gets) =~ /y/
  system 'git add --ignore-removal .'
  print "Input commit message: "
  msg = gets.strip
  system "git commit -m \"#{msg}\" "
  system 'git push origin master'
end
puts "Git done."

puts "Let's go to server."
gets
Net::SSH.start( HOST, USER, :password => PASS ) do |ssh|
  cmd = "rm -rf #{remote_backup_dir}/msystem*"
  puts "Deleting previous backup: '#{cmd}'"
  ssh_exec ssh, cmd
  puts "Deleted."
  
  t = Time.now.strftime "%Y%m%d_%H%M%S"
  cmd = "mv #{remote_app_path} #{remote_backup_dir}/msystem#{t}"
  puts "Making a backup of current: '#{cmd}'"
  ssh_exec ssh, cmd
  puts "Backuped."

  cmd = "git clone #{git_url} #{remote_app_path}"
  puts "Cloning git: '#{cmd}'"
  ssh_exec ssh, cmd
  puts "Cloned."

  cmd = "cd #{remote_app_path} && bundle install --no-deployment && bundle install --deployment"
  puts "Run bundle: '#{cmd}'"
  ssh_exec ssh, cmd
  puts "Bundled."

  cmd = "cp -f #{remote_config_dir}/database.yml #{remote_app_path}/config/"
  puts "Copy database.yml: '#{cmd}'"
  ssh_exec ssh, cmd
  puts "Copied."

  cmd = "cd #{remote_app_path} && rake db:migrate"
  puts "Migrate database: '#{cmd}'"
  ssh_exec ssh, cmd
  puts "Migrated."

  cmd = "touch #{remote_app_path}/tmp/restart.txt"
  puts "Restart Passenger: '#{cmd}'"
  ssh_exec ssh, cmd
  puts "Restarted."

  cmd = "#{remote_app_path}/bin/delayed_job stop && #{remote_app_path}/bin/delayed_job -n 5 start"
  puts "Restart delayed_job workers: '#{cmd}'"
  ssh_exec ssh, cmd
  puts "Restarted."
end

# gateway = Net::SSH::Gateway.open_remote("127.0.0.1", 9150, HOST, 22) 



# uri = URI.parse(HOST)
# puts uri.port
# Net::HTTP.SOCKSProxy('127.0.0.1', 9050).start(uri.host, uri.port, 
#   :use_ssl => uri.scheme == 'https') do |http|
#   p http.get(uri.path)
  
# end