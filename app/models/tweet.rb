class Tweet < ActiveRecord::Base
	has_many :mention, :dependent => :destroy

  	attr_accessible :content, :sentiment, :author
end
