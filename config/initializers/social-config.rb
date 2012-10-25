# Loads the topics config into memory
topics_config_path = File.join(Rails.root,'config','social-config.yml')
SOCIAL_CONFIG = YAML.load_file(topics_config_path)

# Datasift settings
DATASIFT_USERNAME = SOCIAL_CONFIG['datasift']['username']
DATASIFT_APIKEY = SOCIAL_CONFIG['datasift']['apikey']
DATASIFT_QUERY = SOCIAL_CONFIG['datasift']['query']