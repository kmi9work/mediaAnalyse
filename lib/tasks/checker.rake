remote_app_path = "/home/web/public_html/msystem"

namespace :checker do
  desc "Check for delayed_job is working right way"
  task delayed_job: :environment do
    my_logger = Logger.new("#{Rails.root}/log/check_dj.log")
    my_logger.debug "-------- #{DateTime.now.strftime('%d.%m.%Y %H:%M')}: Checking dj started. "
    my_logger.debug "Is process running?"
    str = `pidof delayed_job`
    if str.lines.count <= 0
      my_logger.error "Delayed Job isn't working. Running."
      my_logger.debug `#{remote_app_path}/bin/delayed_job start`
    else
      my_logger.debug "It's running:"
      my_logger.debug str
    end
    my_logger.debug "Check DJ DB."
    if Delayed::Job.count > 0
      my_logger.debug "DJ count: #{Delayed::Job.count}"
      Delayed::Job.find_each do |dj|
        if dj.failed_at
          my_logger.error "DJ failed at #{dj.failed_at.strftime('%d.%m.%Y %H:%M')}."
          my_logger.debug "======="
          my_logger.debug dj.last_error
          my_logger.debug "======="
          if dj.last_error =~ /Xvfb/
            my_logger.debug "Restarting Xvfb..."
            my_logger.debug xpids = `pidof Xvfb`
            my_logger.debug `kill #{xpids}`
            my_logger.debug `/usr/bin/Xvfb :1 -screen 0 1024x768x24 & export DISPLAY=:1 echo 'display is set' firefox &`
          end
          my_logger.debug "Erase failed status."
          dj.failed_at = nil
          dj.save
        end
      end
    else
      my_logger.debug "Check if there are queries with track: true. Start DJ's if there are."
      Query.where(track: true).each do |q|
        ses = q.search_engines
        ses.each do |se|
          fl = (se.tracked_count == 0)
          se.tracked_count = se.queries.where(track: true).count
          se.save
          if Delayed::Job.count == 0 or (fl and se.tracked_count == 1)
            se.delay.track!
          end
        end
      end
    end
  end

  desc "Test task"
  task test: :environment do
    puts Delayed::Job.count
  end
end
