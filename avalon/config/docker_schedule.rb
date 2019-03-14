set :output, "log/whenever_cron.log"
job_type :locking_rake, "source /var/run/secrets/ap-secrets && cd :path && :environment_variable=:environment script/locking_runner :lock_name bundle exec rake :task --silent :output"
job_type :locking_sh, "source /var/run/secrets/ap-secrets && cd /home/app/avalon && (script/locking_runner s3_dropbox_sync /bin/bash script/s3-dropbox-sync.sh) :output"

every 1.minute do
  locking_sh "script/s3-dropbox-sync.sh", :lock_name => "s3_dropbox_sync"
  locking_rake "avalon:batch:ingest", :lock_name => "batch_ingest", :environment => ENV['RAILS_ENV'] || 'production'
end

every 15.minutes do
  locking_rake "avalon:batch:ingest_status_check", :lock_name => "batch_ingest", :environment => ENV['RAILS_ENV'] || 'production'
end

every 1.day do
  locking_rake "avalon:batch:ingest_stalled_check", :lock_name => "batch_ingest", :environment => ENV['RAILS_ENV'] || 'production'
end
