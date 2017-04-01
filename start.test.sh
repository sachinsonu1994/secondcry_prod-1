set -x

#rm -rf public/assets
#rake RAILS_ENV=production tmp:clear tmp:cache:clear assets:clean assets:precompile
#rake RAILS_ENV=production sharetribe:generate_customization_stylesheets_immediately

sudo service mysql restart
sudo service memcached restart

bundle exec rake RAILS_ENV=production ts:index
bundle exec rake RAILS_ENV=production ts:start

nohup bundle exec rake RAILS_ENV=production jobs:work > log/delayed-job-worker.log 2>&1 &
sleep 5
sudo service php5-fpm restart
sudo service nginx restart
