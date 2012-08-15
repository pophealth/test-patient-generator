module HQMF
  class CodedEntry
    # Select the relevant value set that matches the given OID and generate a hash that can be stored on a Record.
    # The hash will be of this format: { "code_set_identified" => [code] }
    #
    # @param [String] oid The target value set.
    # @param [Hash] value_sets Value sets that might contain the OID for which we're searching.
    # @return A Hash of code sets corresponding to the given oid, each containing one randomly selected code.
    def self.select_codes(oid, value_sets)
      # Pick the value set for this DataCriteria. If it can't be found, it is an error from the value set source. We'll add the entry without codes for now.
      index = value_sets.index{|value_set| value_set["oid"] == oid}
      value_sets = index.nil? ? { "code_sets" => [] } : value_sets[index]
      
      code_sets = {}
      value_sets["code_sets"].each do |value_set|
        code_sets[value_set["code_set"]] = [value_set["codes"].sample]
      end
      code_sets
    end
  end
end