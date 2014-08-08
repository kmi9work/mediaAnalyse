# Delayed::Worker.logger = Logger.new(Rails.root.join('log', 'dj.log'))
Delayed::Worker.destroy_failed_jobs = false
Delayed::Worker.sleep_delay = 180
Delayed::Worker.max_attempts = 0
Delayed::Worker.max_run_time = 3600 * 24 * 365 #one year
Delayed::Worker.read_ahead = 10
Delayed::Worker.default_queue_name = 'default'
Delayed::Worker.delay_jobs = !Rails.env.test?