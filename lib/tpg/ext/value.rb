module HQMF
  class Value
    # When actually resolving time, adds or subtracts additional values
    #   e.g. - Value "1a", ModifyingValues "1mo" = "plus 1 year and 1 month"
    # This is convenience for generation so we can resolve time differences when we know the context.
    #   Useful for not needing to convert units and not needing to know what month we're talking about yet (different days in each)
    attr_accessor :modifying_values
    
    def generate_permutations
      
    end
    
    # Sign comes in as 1 or -1 to decide if we're generating values above or below the original
    def generate_permutations(modifier)
      permutations = []

      # If the value is in inclusive, be sure to add itself to the permutation list
      if inclusive
        permutations << Value.new(type, unit, value, inclusive, derived?, expression)
      end

      # Add one of each grain size less than and equal to the current value
      #   e.g. For 1 year, we add 1 year, 1 year and 1 month, 1 year and 1 day, 1 year and 1 hour, and 1 year and 1 min.
      units = ["a", "mo", "d", "h", "min"]
      coarsest_granularity = units.rindex(unit)
      finest_granularity = units.length
      units[coarsest_granularity..finest_granularity].each do |grain|
        # Values here can be PQ or TS. Either way, we add modifying PQ values. These will be resolved to real dates later.
        new_value = Value.new(type, unit, value, inclusive, derived?, expression)
        new_value.modifying_values ||= []

        modifying_value = Value.new(type, grain, 1 * modifier, inclusive, derived?, expression)
        new_value.modifying_values << modifying_value
        
        permutations << new_value
      end
      
      permutations
    end

    # Given a Value that could be PQ or TS and may have one or more modifying values.
    # We'll convert to a Time object and apply all modifiers so we can use this on a coded entry.
    def to_seconds(time)
      
    end
  end
end