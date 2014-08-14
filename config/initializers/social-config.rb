# Loads the topics config into memory
topics_config_path = File.join(Rails.root,'config','social-config.yml')
SOCIAL_CONFIG = YAML.load_file(topics_config_path)

# Datasift settings
DATASIFT_USERNAME = SOCIAL_CONFIG['datasift']['username']
DATASIFT_APIKEY = SOCIAL_CONFIG['datasift']['apikey']
DATASIFT_QUERY = SOCIAL_CONFIG['datasift']['query']

# Twitter settings
TWITTER_APIKEY = SOCIAL_CONFIG['twitter']['apikey']
TWITTER_APISECRET = SOCIAL_CONFIG['twitter']['apisecret']
TWITTER_TOKEN = SOCIAL_CONFIG['twitter']['accesstoken']
TWITTER_TOKENSECRET = SOCIAL_CONFIG['twitter']['accesstokensecret']