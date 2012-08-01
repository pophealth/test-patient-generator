module HQMF
  class Value
    def clone
      Value.new(type.try(:clone), unit.try(:clone), value.try(:clone), inclusive?, derived?, expression.try(:clone))
    end
    
    def self.merge_values(value1, value2, operation, modifier = 1)
      # If only one value in the range is defined, we have no work to do
      return value1 if value2.nil?
      return value2 if value1.nil?
      
      if value1.type == "PQ" && value2.type == "PQ"
        # TODO Combine the value of two PQs. This will be tough if there is a case of time units and no relative TS
        
      elsif value1.type == "TS" && value2.type == "TS"
        # Convert the time strings that we have into actual time objects
        
        
        if operation == "intersection"
          
        elsif operation == "union"
          
        end
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
        pq.value += 1 unless pq.inclusive?
        unit_mapping = {"a" => :years, "mo" => :months, "wk" => :weeks, "d" => :days}
        time = time.advance({unit_mapping[pq.unit] => pq.value.to_i * modifier})
        
        # Form up the modified TS with expected YYYYMMDD formatting (avoid YYYYMD)
        year = time.year
        month = time.month < 10 ? "0#{time.month}" : time.month
        day = time.day < 10 ? "0#{time.day}" : time.day
        
        Value.new("TS", value1.unit, "#{year}#{month}#{day}", value1.inclusive? && value2.inclusive?, false, false)
      end
    end
  end
end