require 'rubygems'
require 'datasift'
require 'yaml'
require 'nokogiri'
require 'open-uri'
require 'pusher'
require 'topics-helper.rb'

# Connect to Datasift stream
def datasift_connect

	puts 'Connecting to Datasift stream...'

	user = DataSift::User.new(DATASIFT_USERNAME, DATASIFT_APIKEY)
	definition = user.createDefinition(DATASIFT_QUERY)
	consumer = definition.getConsumer(DataSift::StreamConsumer::TYPE_HTTP)
	
	puts 'Connected successfully!'

	# Setting up the onStopped handler
	consumer.onStopped do |reason|
		puts 'Stopped: ' + reason
	end

	# Set up the warning event handler.
	consumer.onWarning do |message|
		puts 'WARNING: ' + message
	end

	# Set up the error event handler.
	consumer.onError do |message|
		puts 'ERROR: ' + message
	end

	return consumer

end

# Parses an interaction into a tweet
def parse_interaction_to_tweet(interaction)

	#puts interaction.to_yaml
	tweet = Tweet.new
	tweet.content = interaction['interaction']['content']
	
	begin 
		tweet.sentiment = interaction['salience']['content']['sentiment']
	rescue
		tweet.sentiment = 0
	end

	tweet.author = interaction['interaction']['author']['username']
	tweet.created_at = interaction['interaction']['created_at']

	p '------------ NEW TWEET --------------'
	p tweet.content

	return tweet

end

# parses twitter content for configured topics
def parse_and_save_terms(tweet, interaction)

	@topics.each do |topic|
		case topic.category
		when "twitter-mention"
			parse_and_save_usermentions(topic.id, tweet, interaction)
		when "twitter-hashtag"
			parse_and_save_hashtags(topic.id, tweet)
		end
	end

end

# parses twitter content for people mentions, and saves results to db
def parse_and_save_usermentions(topic_id, tweet, interaction)

	if interaction['twitter'].include? 'mention_ids'

		p 'User mention found'

		interaction['twitter']['mentions'].each do |mention|
			save_mention(topic_id, tweet.id, mention, true)
		end

		# Push new data to front-end
		publish_topic_trends topic_id

	end

end

# parses twitter content for people mentions, and saves results to db
def parse_and_save_hashtags(topic_id, tweet)

	if /#\w+/.match(tweet.content)

		p 'Hashtag found'

		tweet.content.scan(/#\w+/).flatten.each do |hashtag|
			p 'New hashtag: ' + hashtag
			save_mention(topic_id, tweet.id, hashtag, false)
		end
		
		# Push new data to front-end
		publish_topic_trends topic_id

	end

end

# Saves a mention of a term in a tweet
def save_mention(topic_id, tweet_id, term, requires_userdetails)

	term = term.downcase
	db_term = Term.find_or_initialize_by_topic_id_and_source_name(topic_id, term)

	if db_term.new_record?
		db_term.name = term
		db_term.source_name = term
		db_term.topic_id = topic_id
		db_term.processed = !requires_userdetails
		db_term.hide = false
		db_term.save
	end

	mention = Mention.new
	mention.tweet_id = tweet_id
	mention.term_id = db_term.id
	mention.save

end


# publishes trend data for all topics to Pusher
def publish_topic_trends(topic_id)

	topic = Topic.find_by_id(topic_id)

	limit = 30

	# limit to only 7 if user trends
	if topic_id == 1 
		limit = 7
	end

	results = Term.where("terms.topic_id = ? AND terms.hide = ? AND terms.processed = ?", topic.id, false, true).joins(:mention).select("terms.name, terms.image_url, terms.source_name, count(*) as total").group("terms.name, terms.image_url, terms.source_name").order("total DESC").limit(limit)

	if (results != instance_variable_get("@topic_results_data_" + topic.id.to_s))
		p 'Results have changed for: ' + topic.name
	end
	
	Pusher['topic-trends-' + topic.name.downcase].trigger('new-data', results.to_json)
	
end

# Publishes a tweet to Pusher channel
def publish_tweet(tweet)
	Pusher['live-tweets'].trigger('new-tweet', tweet.to_json)
end

# START OF MAIN LOGIC FLOW

# LOGIC: For each tweet received...
	# Parse interaction for people and hash tags
	# Save tweet for sentiment
	# Save term mentions
	# Push updated sentiment/people/tag data to Pusher


# Setup topics
TopicsHelper.initDB
@topics = TopicsHelper.get_topics

# Connect to datasift
consumer = datasift_connect

# Handle tweets as they arrive
consumer.consume(true) do |interaction|
	if interaction
		begin
	
			# parse tweet
			tweet = parse_interaction_to_tweet interaction

			# immediately push to front-end
			publish_tweet(tweet)

			# save the tweet
			tweet.save

			# parse for topic terms
			parse_and_save_terms(tweet, interaction)
			
		rescue Exception => e  
			puts '--------- EXCEPTION -------------'
		    puts e.class
		    puts e.message
		    puts e.backtrace
		end
	end
end

# END OF MAIN LOGIC