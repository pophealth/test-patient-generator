module HQMF
  # Generates a Range to define the timing of a data_criteria
  class TemporalReference
    # 
    #
    # @param [Array] base_patients
    # @return 
    def generate(base_patients)
      if reference.id == "MeasurePeriod"
        matching_time = Generator::hqmf.measure_period.clone
      else
        # First generate patients for the data criteria that this temporal reference points to
        data_criteria = Generator::hqmf.data_criteria(reference.id)
        base_patients = data_criteria.generate(base_patients)

        # Now that the data criteria is defined, we can set our relative time to those generated results
        matching_time = data_criteria.generation_range.first.clone
      end
      
      # TODO add nils where necessary. Ranges should be unbounded, despite the relative time's potential bounds (unless the type specifies)
      if range
        offset = range.try(:clone)
        
        case type
        when "DURING"
          # TODO differentiate between this and CONCURRENT
        when "SBS" # Starts before start
          offset.low.value.insert(0, "-")
        when "SAS" # Starts after start
          offset.low = offset.high
          offset.high = nil
        when "SBE" # Starts before end
          offset.low = offset.high
          offset.high = nil
          offset.low.value.insert(0, "-")
          matching_time.low = matching_time.high
        when "SAE" # Starts after end
          
        when "EBS" # Ends before start

        when "EAS" # Ends after start

        when "EBE" # Ends before end

        when "EAE" # Ends after end

        when "SDU" # Starts during
          matching_time.high.value = nil
        when "EDU" # Ends during

        when "ECW" # Ends concurrent with

        when "SCW" # Starts concurrent with

        when "CONCURRENT"

        end
        
        matching_time = Range.merge_ranges(offset, matching_time)
      end
      
      # Note we return the possible times to the calling data criteria, not patients
      [matching_time]
    end
  end
end