class Topic < ActiveRecord::Base
	has_many :mention, :dependent => :destroy
  	attr_accessible :name, :category
end
