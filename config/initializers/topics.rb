# Loads the topics config into memory
topics_config_path = File.join(Rails.root,'config','twitter-topics.yml')
TOPICS_CONFIG = YAML.load_file(topics_config_path)