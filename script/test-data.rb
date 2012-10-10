# Term.where(:topic_id => 4).joins(:mention).select("terms.name, count(*) as total").group("terms.name").order("total DESC").limit(20).each do |result|
# 	puts result.name + ', ' + result.total.to_s
# end


Term.joins(:topic).where("topics.category = 'twitter-mention' AND terms.processed = 'f'").each do |result|
	puts result.source_name
end


