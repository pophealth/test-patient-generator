module TPG
  # The Traverser will step through the tree of a clinical quality measure's logic.
  # Visitors who need to act on the logic tree can be attached and given a chance to do
  # work at each context. The goal is to traverse once, but perform arbitrarily many actions.
  class Traverser
    # @param [HqmfDocument] hqmf A model representing the logic of a given HQMF document.
    # @param [Hash] value_sets All of the 
    def initialize(hqmf, value_sets)
      @hqmf = hqmf
      @value_sets = value_sets
      @visitors = [] # All Visitors who will act at each step of the HQMF logic tree.
    end
    
    # Add all of the Visitors that will be acting on this traversal. Each will be called at
    # each logical juncture of the HQMF document.
    #
    # @param [Visitor] visitors Some amount of Visitors who will be called during traversal
    def attach_visitors(visitors)
      @visitors = []
      
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
        hook = "#{visitor.class::VISITING_PREFIX}_#{task}".to_sym
        visitor.send(hook, data) if visitor.respond_to? hook
      end
    end
    
    # Kick off the whole traversal
    #
    # @param [Visitor] visitors Some amount of Visitors that will be attached for this traversal.
    def traverse(*visitors)
      attach_visitors(visitors)
      
      traverse_population_criteria
      call_visitors('eof', nil) # Trigger the completion of the traversal
    end
    
    # Dive into each population criteria for the given HQMF file
    def traverse_population_criteria
      ["IPP"].each do |population|
        call_visitors('population', @hqmf.population_criteria(population))
        traverse_preconditions(@hqmf.population_criteria(population))
      end
    end
    
    # Recursively traverse all preconditions of the given precondition
    #
    # @param [Precondition] precondition The current precondition to look at
    def traverse_preconditions(preconditions)
      if preconditions.conjunction?
        # We're somewhere in the middle or top of the tree
        call_visitors('conjunction', preconditions)
        preconditions.preconditions.each do |precondition|
          traverse_preconditions(precondition)
        end
      elsif preconditions.reference
        # We've hit a leaf node - This is a data criteria reference
        call_visitors('data_criteria', @hqmf.data_criteria(preconditions.reference.id))
      end
    end
  end
end