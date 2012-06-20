module HQMF
  class Value
    attr_accessor :modifying_values
    
    def generate_permutations
      
    end

    def generate_permutations(modifier, width = nil)
      return [nil] if value.nil?
      permutations = []

      # If the value is in inclusive, be sure to add itself to the permutation list
      if inclusive
        permutations << Value.new(type, unit, value, inclusive, derived?, expression)
      end

      # For TS values
      unit = width if unit.nil?

      coarsest_granularity = units.rindex(unit)
      finest_granularity = units.length
      units[coarsest_granularity..finest_granularity].each do |grain|
        # Values here can be PQ or TS. Either way, we add modifying PQ values. These will be resolved to real dates later.
        new_value = Value.new(type, unit, value, inclusive, derived?, expression)
        new_value.modifying_values ||= []

        modifying_value = Value.new("PQ", grain, 1 * modifier, inclusive, derived?, expression)
        new_value.modifying_values << modifying_value
        
        permutations << new_value
      end
      
      permutations
    end

    # Given a Value that could be PQ or TS and may have one or more modifying values.
    # We'll convert to a Time object and apply all modifiers so we can use this on a coded entry.
    def to_seconds(time)
      year = time.value[0,3]
      month = time.value[3,4]
      day = time.value[4,5]
      
      Time.gm(year: year, month: month, day: day).to_i
    end
    
    def self.merge_values
      
    end
      
  end
end