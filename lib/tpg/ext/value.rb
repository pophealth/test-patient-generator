module HQMF
  class Value
    include Comparable
    
    # Perform a deep copy of this Value.
    #
    # @return A deep copy of this Value.
    def clone
      Value.new(type.try(:clone), unit.try(:clone), value.try(:clone), inclusive?, derived?, expression.try(:clone))
    end

    #
    def format      
#      unit_mapping = {"a" => "years", "mo" => "months", "wk" => "weeks", "d" => "days"}
#      pretty_unit = unit_mapping[unit] if unit
#      pretty_unit ||= unit
      
      { "scalar" => value, "units" => unit }
    end

    # 
    #
    # @param [Value] value1
    # @param [Value] value2
    # @return 
    def self.merge_values(value1, value2)
      # If only one value in the range is defined, we have no work to do
      return value1 if value2.nil?
      return value2 if value1.nil?
      
      if value1.type == "PQ" && value2.type == "PQ"
        # TODO Combine the value of two PQs. This will be tough if there is a case of time units and no relative TS
        
      elsif value1.type == "TS" && value2.type == "TS"
        # Convert the time strings that we have into actual time objects
        
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
        time = time.advance({unit_mapping[pq.unit] => pq.value.to_i})
        
        # Form up the modified TS with expected YYYYMMDD formatting (avoid YYYYMD)
        year = time.year
        month = time.month < 10 ? "0#{time.month}" : time.month
        day = time.day < 10 ? "0#{time.day}" : time.day
        
        Value.new("TS", value1.unit, "#{year}#{month}#{day}", value1.inclusive? && value2.inclusive?, false, false)
      end
    end
    
    def self.time_to_ts(time)
      year = time.year
      month = time.month < 10 ? "0#{time.month}" : time.month
      day = time.day < 10 ? "0#{time.day}" : time.day
      
      "#{year}#{month}#{day}"
    end
    
    #
    #
    # @return
    def to_seconds
      to_time_object.to_i
    end
    
    # 
    #
    # @return 
    def to_time_object
      year = value[0,4].to_i
      month = value[4,2].to_i
      day = value[6,2].to_i
      hour = 0
      minute = 0
      second = 0
      if (value.length > 8)
        hour = value[8,2].to_i
        minute = value[10,2].to_i
        second = value[12,2].to_i
      end
      
      Time.new(year, month, day, hour, minute, second)
    end
    
    def <=>(value)
      # So far there has only been a need to compare TS Values
      if type == "TS" && value.type == "TS"
        time = to_time_object
        other = value.value
        
        if time < other
          -1
        elsif time > other
          1
        else
          0
        end
      end
    end
  end
end