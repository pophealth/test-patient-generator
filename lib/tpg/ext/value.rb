module HQMF
  class Value
    def self.negotiate_value(value1, value2)
      
    end
    
    def self.merge_values(value1, value2, modifier = 1)
      # If only one value in the range is defined, we have no work to do
      return value1 if value2.nil?
      return value2 if value1.nil?
      
      if value1.type == "PQ" && value2.type == "PQ"
        # TODO Combine the value of two PQs. This will be tough if there is a case of time units and no relative TS
        binding.pry
      elsif value1.type == "TS" && value2.type == "TS"
        # TODO Resolve two timestamps
        Value.negotiate_value(value1, value2)
        binding.pry
      else
        # One PQ and one TS
        pq = value1.type == "PQ" ? value1 : value2
        ts = value1.type == "TS" ? value1 : value2
        
        # Create a Ruby object to represent the TS
        year = ts.value[0,4]
        month = ts.value[4,2]
        day = ts.value[6,2]
        time = Time.new(year, month, day)
        
        # Advance that time forward the amount the PQ specifies. Convert units to symbols for advance function.
        unit_mapping = {"a" => :years, "mo" => :months, "wk" => :weeks, "d" => :days}
        time = time.advance({unit_mapping[pq.unit] => pq.value.to_i * modifier})
        
        # Form up the modified TS with expected YYYYMMDD formatting (avoid YYYYMD)
        year = time.year
        month = time.month < 10 ? "0#{time.month}" : time.month
        day = time.day < 10 ? "0#{time.day}" : time.day
        
        Value.new("TS", value1.unit, "#{year}#{month}#{day}", value1.inclusive? && value2.inclusive?, false, false)
      end
    end
    
    def generate_permutations(modifier)
      return [nil] if value.nil?
      
      permutations = []

      # TODO Actually generate permutations. We're only generating matches right now.
      if type == "TS"
        permutations << self
      elsif type == "PQ"
        permutations << self
      else
        binding.pry
      end
      
      permutations
    end

    # Given a Value that could be PQ or TS and may have one or more modifying values.
    # We'll convert to a Time object and apply all modifiers so we can use this on a coded entry.
    def to_seconds
      year = value[0,4]
      month = value[4,2]
      day = value[6,2]
      
      Time.new(year, month, day).to_i
    end
  end
end