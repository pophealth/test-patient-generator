module HQMF
  class PopulationCriteria
    # 
    #
    # @param [Array] base_patients
    # @return
    def generate(base_patients)
      # All population criteria begin with a single conjunction precondition
      preconditions.first.generate(base_patients)
    end
  end
end