module HQMF
  class Value
    attr_accessor :modifying_values
    
    def self.negotiate_value(value1, value2)
      
    end
    
    def self.merge_values(value1, value2, modifier = 1)
      return nil if value1.nil? && value2.nil?
      return value1 if value2.nil?
      return value2 if value1.nil?
      
      if value1.type == "PQ" && value2.type == "PQ"
        # I'm assuming the easy case of units are equal
        value1.value += merging_value.value
      elsif value1.type == "TS" && value2.type == "TS"
        # I haven't seen this yet
        binding.pry
      else # one PQ and one TS
        pq = value1.type == "PQ" ? value1 : value2
        ts = value1.type == "TS" ? value1 : value2
        
        year = ts.value[0,4]
        month = ts.value[4,2]
        day = ts.value[6,2]
        
        time = Time.gm(year, month, day)
        case pq.unit
        when "a"
          time = time.advance(years: pq.value.to_i * modifier)
        when "m"
          binding.pry
        when "w"
          binding.pry
        when "d"
          binding.pry
        end
        
        year = time.year
        month = time.month < 10 ? "0#{time.month}" : time.month
        day = time.day < 10 ? "0#{time.day}" : time.day
        
        Value.new("TS", value1.unit, "#{year}#{month}#{day}", value1.inclusive? && value2.inclusive?, false, false)
      end
    end
    
    def generate_permutations(modifier)
      return [nil] if value.nil?
      
      permutations = []

      # If the value is in inclusive, be sure to add itself to the permutation list
      #if inclusive
      #  permutations << Value.new(type, unit, value, inclusive, derived?, expression)
      #end

      if type == "TS"
        permutations << self
      elsif type == "PQ"
        permutations << self
      else
        binding.pry
      end

      #coarsest_granularity = units.rindex(unit)
      #finest_granularity = units.length
      #units[coarsest_granularity..finest_granularity].each do |grain|
        # Values here can be PQ or TS. Either way, we add modifying PQ values. These will be resolved to real dates later.
        #new_value = Value.new(type, unit, value, inclusive, derived?, expression)
        #new_value.modifying_values ||= []

        #modifying_value = Value.new("PQ", grain, 1 * modifier, inclusive, derived?, expression)
        #new_value.modifying_values << modifying_value
        
        #permutations << new_value
      #end
      
      permutations
    end

    # Given a Value that could be PQ or TS and may have one or more modifying values.
    # We'll convert to a Time object and apply all modifiers so we can use this on a coded entry.
    def to_seconds
      year = value[0,4]
      month = value[4,2]
      day = value[6,2]
      
      Time.gm(year, month, day).to_i
    end
  end
end