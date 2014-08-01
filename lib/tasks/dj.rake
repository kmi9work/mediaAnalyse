remote_app_path = "/home/web/public_html/msystem"

namespace :dj do
  desc "Restart Delayed Jobs."
  task restart: :environment do
    `#{remote_app_path}/bin/delayed_job -n3 restart`
    Delayed::Job.all.each{|j| j.unlock; j.save}
  end
end