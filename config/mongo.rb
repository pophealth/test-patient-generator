path = File.join('config', 'mongo.yml')
config = File.open(path).read
session = YAML.load(config)

Mongoid.configure do |config|
  config.sessions = {
    default: {
      hosts: session["hosts"],
      database: session["database"]
    }
  }
end

MONGO_DB = Mongoid.default_session