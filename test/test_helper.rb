require_relative "./simplecov"
require_relative '../lib/test-patient-generator'

require 'pry'
require 'minitest/autorun'

# Patch on some useful utility functions for our tests.
class MiniTest::Unit::TestCase
  # Converts string IDs into Mongoid IDs so we can query properly. 
  # 
  # @param [String] collection The directory where fixtures to be affected are located. Typically, this is the name of the collection to which the fixture belongs.
  # @param [Array] id_attributes A splat of fields on documents in the collection that need to be converted.
  def collection_fixtures(collection, *id_attributes)
    Mongoid.session(:default)[collection].drop
    Dir.glob(File.join(Rails.root, 'test', 'fixtures', collection, '*.json')).each do |json_fixture_file|
      fixture_json = JSON.parse(File.read(json_fixture_file), max_nesting: 250)
      id_attributes.each do |attr|
        next if fixture_json[attr].nil?

        if fixture_json[attr].kind_of? Array
          fixture_json[attr] = fixture_json[attr].collect{|att| Moped::BSON::ObjectId(att)}
        else
          fixture_json[attr] = Moped::BSON::ObjectId(fixture_json[attr])
        end
      end
      Mongoid.default_session[collection].insert(fixture_json)
    end
  end

  # Delete all collections from the database.
  def dump_database
    Mongoid.session(:default).collections.each do |collection|
      collection.drop unless collection.name.include?('system.') 
    end
  end
end