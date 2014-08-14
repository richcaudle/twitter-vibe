# Twitter Vibe Demonstration

This is a demo trending wall for Twitter posts. It displays live tweets and aggregates the top hashtags and mentions.

This demo was created for internal use only. If you wish to adapt it for production or public display then you must adhere to the Twitter [Terms of Service](https://dev.twitter.com/terms/api-terms), including the [Developer Display Requirements](https://dev.twitter.com/terms/display-requirements).

## Requirements

* Ruby 1.9.3
* Run **bundle install** to install all required Gems

## Settings

* Enter your Twitter & Datasift account details in **config/social-config.yml**
* Enter your Pusher application details in **config/initializers/pusher.rb**

## Run It!

Create and migrate the database...

* **bundle exec rake db:migrate**

To run the app you need to run these three commands...

* **rails server** - This starts the rails server
* **rails runner script/data-collector.rb** - This collects data from DataSift
* **rails runner script/tasks.rb** - This collects user details from Twitter to complete the UI