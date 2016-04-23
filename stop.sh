set -x

bundle exec rake RAILS_ENV=production ts:stop
sudo service nginx stop

sudo pkill -f rake
sleep 5
sudo pkill -f rake
sleep 5
ps -ef | grep rake
