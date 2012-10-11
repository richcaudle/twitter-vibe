require 'open-uri'
require 'topics-helper.rb'
require 'sentimentresult.rb'

# Settings
@max_tweet_age_in_mins = 120
@max_tweets_analyse = 50


def process_twitter_usernames

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

		p 'Requesting: ' + "https://api.twitter.com/1.1/users/lookup.json?screen_name=" + query

		content = open("https://api.twitter.com/1.1/users/lookup.json?screen_name=" + query).read

		p content

		# Save name for each term as returned

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

		results = Term.where(:topic_id => topic.id).joins(:mention).select("terms.name, count(*) as total").group("terms.name").order("total DESC").limit(20)
	
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

	# push latest data to front-end
	publish_sentiment_data
	publish_topic_trends

	#process_twitter_usernames
	delete_old_data

	sleep(3)

end


# END OF MAIN LOGIC