bundle exec rake RAILS_ENV=production assets:clean

bundle exec rake RAILS_ENV=production ts:index
bundle exec rake RAILS_ENV=production ts:start
bundle exec rake RAILS_ENV=production assets:precompile

sudo service mysql restart
nohup bundle exec rake RAILS_ENV=production jobs:work > log/delayed-job-worker.log 2>&1 &
sudo service nginx restart
#nohup bundle exec rails server -e production -b 0.0.0.0 > log/web-server.log 2>&1 &
