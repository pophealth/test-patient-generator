require 'pry'

path = File.join('config', 'mongo.yml')
config = File.open(path).read
session = YAML.load(config)
environment = "development"

Mongoid.configure do |config|
  config.sessions = {
    default: {
      hosts: session[environment]["hosts"],
      database: session[environment]["database"]
    }
  }

  binding.pry
end

binding.pry
MONGO_DB = Mongoid.default_session
binding.pry