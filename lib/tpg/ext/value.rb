module HQMF
  class Value
    def generate_permutations
      
    end
    
    def generate_permutations_to_pass
      binding.pry
      
      return []
      permutations = []

      time = Time.new(criteria["effective_time"]["high"]["value"])
      time = adjust_time(time, criteria["value"], criteria["units"])

      units = ["a", "mo", "d", "h", "min"]
      coarsest_granularity = units.rindex(criteria["unit"])
      finest_granularity = units.length
      units[coarsest_granularity..finest_granularity].each do |unit|

      end

      case vector["unit"]
      when "a"
        temporal_text += "year"
      when "mo"
        temporal_text += "month"
      when "d"
        temporal_text += "day"
      when "h"
        temporal_text += "hour"
      when "min"
        temporal_text += "minute"
      end
      temporal_text += "s" if vector["value"] != 1

      temporal_text
    end
    
    def generate_permutations_to_fail
      
    end
  end
end