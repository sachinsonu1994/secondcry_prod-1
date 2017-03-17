set -x

bundle exec rake RAILS_ENV=production ts:stop

sudo pkill -f rake
sleep 5
sudo pkill -f rake
sleep 5
sudo pkill -f rake

sudo pkill -f rails
