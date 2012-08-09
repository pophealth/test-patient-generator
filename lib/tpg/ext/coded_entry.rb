module HQMF
  class CodedEntry
    def generate_codes(value_sets)
      code_sets = {}
      value_sets["code_sets"].each do |value_set|
        code_sets[value_set["code_set"]] = value_set["codes"].sample
      end
    end
  end
end