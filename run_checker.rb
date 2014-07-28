  require 'daemons'
  
  Daemons.run_proc('checker') do
    loop do
      `cd /home/web/public_html/msystem && export PATH=/usr/local/jdk/bin:/usr/local/rvm/gems/ruby-2.1.2/bin:/usr/local/rvm/gems/ruby-2.1.2@global/bin:/usr/local/rvm/rubies/ruby-2.1.2/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/rvm/bin:/usr/local/bin:/usr/X11R6/bin:/root/bin && RAILS_ENV=production rake checker:delayed_job`
      sleep(1800)
    end
  end