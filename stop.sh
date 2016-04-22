bundle exec rake RAILS_ENV=production ts:stop
sudo service nginx stop
sudo pkill -f rake
sleep 3
sudo pkill -f rake
