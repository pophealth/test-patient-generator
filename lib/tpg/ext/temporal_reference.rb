module HQMF
  # Generates a Range to define the timing of a data_criteria
  class TemporalReference
    def generate(base_patients)
      
    end
    
    def generate_pass(base_patients)
      
    end
    
    def generate_fail(base_patients)
      
    end
    
    def generate_match(base_patients)
      acceptable_times = []
      
      if reference.id == "MeasurePeriod"
        matching_time = Generator::hqmf.measure_period
      else
        # First generate patients for the data criteria that this temporal reference points to
        data_criteria = Generator::hqmf.data_criteria(reference.id)
        base_patients = data_criteria.generate_match(base_patients)

        # Now that the data criteria is defined, we can set our relative time to those generated results
        matching_time = data_criteria.generation_range.first
      end
      
      if range
        case type
        when "DURING"

        when "SBS" # Starts before start

        when "SAS" # Starts after start

        when "SBE" # Starts before end
          range.low = range.high
          range.high = nil
          range.low.value.insert(0, "-")
          matching_time.low = matching_time.high
        when "SAE" # Starts after end

        when "EBS" # Ends before start

        when "EAS" # Ends after start

        when "EBE" # Ends before end

        when "EAE" # Ends after end

        when "SDU" # Starts during

        when "EDU" # Ends during

        when "ECW" # Ends concurrent with

        when "SCW" # Starts concurrent with

        when "CONCURRENT"

        end
      end
      
      matching_time = Range.merge_ranges(range, matching_time) if range

      # Note we return the possible times to the calling data criteria, not patients
      return matching_time.generate_permutations(1, 1)
    end
    
    private
    
    def generate_permutations(base_patients)

    end
  end
end