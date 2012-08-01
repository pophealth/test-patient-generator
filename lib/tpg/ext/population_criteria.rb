module HQMF
  # Takes a population
  # Returns a new population
  class PopulationCriteria
    def generate(base_patients)
      # All population criteria begin with a single conjunction precondition
      preconditions.first.generate(base_patients)
    end
  end
end