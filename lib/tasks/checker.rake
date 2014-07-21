remote_app_path = "/home/web/public_html/msystem"

namespace :checker do
  desc "Check for delayed_job is working right way"
  task delayed_job: :environment do
    my_logger = Logger.new("#{Rails.root}/log/check_dj.log")
    my_logger.debug "-------- #{DateTime.now.strftime('%d.%m.%Y %H:%M')}: Checking dj started. "
    my_logger.debug "Is process running?"
    str = `ps axu | grep delayed_job`
    if str.lines.count <= 1
      puts "Delayed Job isn't working. Running."
      `#{remote_app_path}/bin/delayed_job start`
    else
      puts "It's running:"
      puts str
    end
    puts "Check DJ DB."
    if Delayed::Job.count > 0
      Delayed::Job.find_each do |dj|
        if dj.failed_at
          if dj.last_error =~ /Xvfb/
            xpids = `pidof Xvfb`
            `kill #{xpids}`
          end
          my_logger.error "DJ failed at #{dj.failed_at.strftime('%d.%m.%Y %H:%M')}."
          my_logger.debug "======="
          my_logger.debug dj.last_error
          my_logger.debug "======="
          my_logger.debug "Erase failed status."
          dj.failed_at = nil
          dj.save
        end
      end
    else
      #check if there is any Queries with track: true
    end

    puts "Check "
  end

  desc "Test task"
  task test: :environment do
    puts Delayed::Job.count
  end
end
