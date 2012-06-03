module TPG
  # The Traverser will step through the tree of a clinical quality measure's logic.
  # Visitors who need to act on the logic tree can be attached and given a chance to do
  # work at each context. The goal is to traverse once, but perform arbitrarily many actions.
  class Traverser
    # @hqmf - 
    # @value_sets - 
    # @visitors - 
    def initialize(hqmf, value_sets)
      @hqmf = hqmf
      @value_sets = value_sets
      @visitors = []
    end
    
    # Add all of the Visitors that will be acting on this traversal. Each will be called at
    # each logical juncture of the HQMF document.
    #
    # @param [Visitor] visitors Some amount of Visitors who will be called during traversal
    def attach_visitors(*visitors)
      visitors.each do |visitor|
        @visitors << visitor
      end
    end
    
    # At each logical juncture of the HQMF document, all attached Visitors will have a chance
    # to act on the current location in the tree and the data that is there.
    #
    # @param [Object] data - Whatever data exists at the current location in the tree.
    def call_visitors(task, data)
      @visitors.each do |visitor|
        visitor.try("#{visitor.class::VISITING_PREFIX}_#{task}".to_sym, data)
      end
    end
    
    # Kick off the whole traversal
    def traverse
      traverse_population_criteria
    end
    
    # Dive into each population criteria for the given HQMF file
    def traverse_population_criteria
      ["IPP"].each do |population|
        call_visitors('population', @hqmf.population_criteria(population))
        traverse_population_preconditions(@hqmf.population_criteria(population))
      end
    end
    
    # Recursively traverse all preconditions of the given precondition
    #
    # @param [Precondition] precondition The current precondition to look at
    def traverse_population_preconditions(precondition)
      call_visitors('precondition', precondition)
      
      binding.pry
      
      if criteria.conjunction? # We're at the top of the tree
        criteria.preconditions.each do |precondition|
          patients.concat(generate_patients_from_preconditions(precondition, base_patient))
        end
      else # We're somewhere in the middle
        conjunction = criteria["conjunction_code"]
        criteria.preconditions.each do |precondition|
          if precondition.reference # We've hit a leaf node - This is a data criteria reference
            patients.concat(generate_patients_from_data_criteria(data_criteria[precondition.reference], base_patient))
          else # There are additional layers below
            patients.concat(generate_patients_from_preconditions(precondition, base_patient))
          end
        end if criteria.preconditions
      end
    end
  end
end