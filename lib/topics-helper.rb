module TopicsHelper

	def TopicsHelper.initDB

		# This script checks that all Twitter topics exist in the database
		puts 'TOPICS: Initializing Topics...'

		# Read topic lists from YAML file
		TOPICS_CONFIG['topics'].each do |topic|
			
			# Find topic item in DB
			db_topic = Topic.find_or_initialize_by_name(topic['name'])

			if db_topic.new_record?
				puts 'TOPICS: Saving new topic: ' + topic['name']
			end

			db_topic.category = topic['category']
			db_topic.save

		end

		puts 'TOPICS: Finished Initializing Topics Successfully!'

	end

	# Gets a list of all terms in the database
	def TopicsHelper.get_topics

		return Topic.all

	end

end
