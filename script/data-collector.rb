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

	user = DataSift::User.new("rich_caudle", "bc583ac6e70761eb16f4f67e128ea824")
	consumer = user.getConsumer(DataSift::StreamConsumer::TYPE_HTTP, "746c1bdc0f1526e8ddce24b0e60eb145")
	
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
	tweet.sentiment = interaction['salience']['content']['sentiment']
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
		interaction['twitter']['mentions'].each do |mention|
			save_mention(topic_id, tweet.id, mention, true)
		end
	end

end

# parses twitter content for people mentions, and saves results to db
def parse_and_save_hashtags(topic_id, tweet)

	tweet.content.scan(/#\w+/).flatten.each do |hashtag|
		p 'New hashtag: ' + hashtag
		save_mention(topic_id, tweet.id, hashtag, false)
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