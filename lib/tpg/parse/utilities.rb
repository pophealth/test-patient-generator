module TPG
  module Parse
    class Utilities
      # The names of criteria from HQMF usually have the category contained within them from auto-generated text.
      # Here we attempt to parse out the category and form a more human readable version of the name.
      #
      # @param [String] name The name of the criteria combined with its category.
      # @param [String] category The category of an HQMF criteria.
      # @return [String] A best guess of what the criteria name should be.
      def self.parse_criteria_name(name, category)
        return name unless category
        
        last_word_of_category = category.split.last.gsub(/_/, ' ')
        name =~ /#{last_word_of_category}. (.*)/i # The portion after autoformatted text, i.e. actual name (e.g. pneumococcal vaccine)
        
        name = $1
      end
      
      # Takes criteria and does a best effort to produce the most human readable category that briefly describes the HQMF criteria.
      #
      # @param [String] criteria The HQMF criteria that we're trying to describe.
      # @return The category that describes the given HQMF criteria.
      def self.parse_criteria_category(criteria)
        category = criteria["standard_category"]
        
        # Let's try to get more specific. QDS data type is best so use it if available. Otherwise see if we have hardcoded improvements.
        category_mapping = { "individual_characteristic" => "patient characteristic" }
        if criteria["qds_data_type"]
          category = criteria["qds_data_type"].gsub(/_/, " ") # "medication_administered" = "medication administered"
        elsif category_mapping[category]
          category = category_mapping[category]
        end

        category
      end
    end
  end
end