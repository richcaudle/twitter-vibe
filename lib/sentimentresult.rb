class SentimentResult

	attr_accessor :positive, :negative, :updated

	def initialize(positive, negative)
		@positive = positive
		@negative = -negative
		@updated = Time.now
	end

end