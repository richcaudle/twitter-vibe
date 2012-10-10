class Mention < ActiveRecord::Base
	belongs_to :term
	belongs_to :tweet

  	attr_accessible :term_id, :tweet_id
end
