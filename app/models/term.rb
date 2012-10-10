class Term < ActiveRecord::Base
	belongs_to :topic
	has_many :mention, :dependent => :destroy
  	
  	attr_accessible :name, :source_name, :processed, :topic_id
end
