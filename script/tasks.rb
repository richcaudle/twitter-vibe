require 'open-uri'
require 'topics-helper.rb'
require 'sentimentresult.rb'
require 'oauth'
require 'json'

# Settings
@max_tweet_age_in_mins = 120
@max_tweets_analyse = 50

def process_twitter_usernames

	# Get twitter auth token
	twitter_access_token = prepare_access_token('19562292-7mkTsZkGVjuFwRaWVA1cVUlNBdMSnp98KuNbN08lo','Ju0RRXGlCrQCnQ7ZHEQTHlnfMZPUSkSQFI5lmrXtWIE')

	# Get list of terms with no 'name' value, whose topic is type twitter-username
	terms = Term.joins(:topic).where("topics.category = 'twitter-mention' AND terms.processed = 'f'").limit(100)

	if !(terms.empty?)

		# Send request to twitter
		query = ''

		terms.each do |term|

			if query.length > 0
				query += ','
			end

			query += term.source_name

		end

		url = "https://api.twitter.com/1.1/users/lookup.json?screen_name=" + query
		
		p 'Requesting: ' + url

		response = twitter_access_token.request(:get, url)

		data = JSON.parse(response.body)

		# Save name for each term as returned
		data.each do |user_profile|

			db_term = Term.find_by_name(user_profile['screen_name'].downcase)
			db_term.name = user_profile['name']
			db_term.image_url = user_profile['profile_image_url']
			db_term.processed = true
			db_term.save

		end

	end

end

def delete_old_data

	min_date = (Time.now - @max_tweet_age_in_mins.minutes).to_datetime
	Tweet.where("created_at < :min_date", {:min_date => min_date}).destroy_all

end

# publishes sentiment data from the database
def publish_sentiment_data
	forSentiment = Tweet.order("created_at DESC").limit(@max_tweets_analyse)
	positiveSentiment = forSentiment.where('sentiment > 0').sum(:sentiment)
	negativeSentiment = forSentiment.where('sentiment < 0').sum(:sentiment)
	sentiment = SentimentResult.new(positiveSentiment, negativeSentiment)

	Pusher['sentiment-results'].trigger('new-data', sentiment.to_json)
end

# publishes trend data for all topics to Pusher
def publish_topic_trends

	@topics.each do |topic|

		# limit to only 7 if user trends
		limit = 30 
		
		if topic.id == 1 
			limit = 7
		end

		results = Term.where("terms.topic_id = ? AND terms.hide = ? AND terms.processed = ?", topic.id, false, true).joins(:mention).select("terms.name, terms.image_url, terms.source_name, count(*) as total").group("terms.name, terms.image_url, terms.source_name").order("total DESC").limit(limit)

		if (results != instance_variable_get("@topic_results_data_" + topic.id.to_s)) || ((instance_variable_get("@topic_results_pushed_" + topic.id.to_s) + 20) < Time.now)
			
			if (results != instance_variable_get("@topic_results_data_" + topic.id.to_s))
				p 'Results have changed for: ' + topic.name
			end
			
			Pusher['topic-trends-' + topic.name.downcase].trigger('new-data', results.to_json)

			instance_variable_set("@topic_results_data_" + topic.id.to_s, results)
			instance_variable_set("@topic_results_pushed_" + topic.id.to_s, Time.now)

		end		

	end

end

# Exchange your oauth_token and oauth_token_secret for an AccessToken instance.
def prepare_access_token(oauth_token, oauth_token_secret)
  
  consumer = OAuth::Consumer.new("M7rdMmxnRe07eevjr2qNzg", "6Id7IfEYKNA5AM1PTHHitnEd6KgHxXe2NHfNzR2CZhk",
    { :site => "http://api.twitter.com",
      :scheme => :header
    })

  # now create the access token object from passed values
  token_hash = { :oauth_token => oauth_token,
                 :oauth_token_secret => oauth_token_secret
               }
  access_token = OAuth::AccessToken.from_hash(consumer, token_hash )
  return access_token

end


# START OF MAIN LOGIC FLOW

# LOGIC: For each iteration...
	# Get Twitter user names
	# Delete old data
	# Sleep for x seconds

# Setup topics
TopicsHelper.initDB
@topics = TopicsHelper.get_topics

# Forever iterate this loop
while true do

	# Update twitter user details
	process_twitter_usernames

	# push latest data to front-end
	#publish_sentiment_data
	publish_topic_trends

	#process_twitter_usernames
	delete_old_data

	sleep(5)

end


# END OF MAIN LOGIC