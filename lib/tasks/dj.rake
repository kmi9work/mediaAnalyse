remote_app_path = "/home/web/public_html/msystem"

namespace :dj do
  desc "Restart Delayed Jobs."
  task restart: :environment do
    puts `#{remote_app_path}/bin/delayed_job -n3 restart`
    Delayed::Job.all.each do |j|
      j.unlock
      j.failed_at = nil
      puts j.id
      puts '---------------------'
      puts j.last_error
      puts '====================='
      j.save
    end
  end
end