module TPG
  # A Generator serves as a visitor to an HQMF Traverser.
  #
  # At each step, the generator will create as many patients as possible to exhaustively test the logic
  # of the given clinical quality measure.
  class Generator
    VISITING_PREFIX = "generate_from"
    
    # @param [Record] base_patient An original patient from whom we will generate more to exhaustively test CQM logic.
    def initialize(base_patient = Generator.create_base_patient)
      @patients = [] # Our bin for patients once we're done with them.
      @pending_patients = [base_patient] # Our patients who are under construction. Carry them into the next population.
    end
    
    # Generate patients from an HQMF file and its matching value sets file. These patients are designed to test all
    # paths through the logic of this particular clinical quality measure.
    def self.generate_patients(hqmf, value_sets)
      traverser = TPG::Traverser.new(hqmf, value_sets)
      generator = TPG::Generator.new()
      
      traverser.attach_visitors(generator)
      traverser.traverse()
      
      generator.patients
    end
    
    # Create a patient with trivial demographic information and no coded entries.
    #
    # @return A Record with a blank slate
    def self.create_base_patient
      patient = Record.new
      patient.elimination_population = nil
      patient.elimination_reason = nil
      
      patient = Randomizer.attach_random_demographics(patient)
    end
    
    # Take an existing patient with some coded entries on them and redefine their trivial demographic information
    #
    # @param [Record] base_patient The patient that we're using as a base to create a new one
    # @return A new Record with an identical medical history to the given patient but new trivial demographic information
    def self.extend_patient(base_patient)
      patient = base_patient.clone()
      
      patient = Randomizer.attach_random_demographics(patient)
    end
    
    # Fill in any missing details that should be filled in on a patient. These include: age, gender, and first name.
    #
    # @param [Record] patient The patient for whom we are about to fill in remaining demographic information.
    # @return A patient with guaranteed complete information necessary for standard formats.
    def self.finalize_patient(patient)
      if patient.birthdate.nil?
        patient.birthdate = Randomizer.generate_birthdate()
        patient.birthdate = Time.now.to_i
      end
      
      if patient.gender.nil?
        # Set gender
        rand(2) == 0 ? patient.gender = "M" : patient.gender = "F"
        patient.first = Randomizer.randomize_first_name(patient.gender)
      end
      
      patient
    end
    
    # Traversal Hook that marks all pending patients with the current population name as the one that elimiantes them.
    # If they are logically eliminated, the reason will be added by the condition that removes them from the pool.
    #
    # @param [PopulationCriteria] population The Population Criteria that is currently being visited.
    def generate_from_population(population)
      @pending_patients.each do |patient|
        patient.elimination_population = population
      end
    end
    
    # Traversal Hook that will determine what kind of precondition we're looking at and hand off to the appropriate handler.
    #
    # @param [Precondition] precondition The precondition that is currently being visited.
    def generate_from_precondition(precondition)
      binding.pry
    end
    
    # Traversal Hook for when the document is completed. We'll move all pending_patients into the patients array
    # and finalize everyone to be sure they are fully fleshed out.
    def generate_from_eof(data)
      until @pending_patients.empty?
        patient = @pending_patients.shift
        patient.elimination_population = 'eof'
        patients.elimination_reason = 'eof'
        @patients << patient
      end
      
      @patients.each do |patient|
        patient = Generator.finalize_patient(patient)
      end
    end
    
    # 
    def generate_from_operator()
      patients = []

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

      patients
    end

    def generate_patients_from_data_criteria(criteria, base_patient)
      patients = []

      # If this is not a coded entry and just a property, it's simple generation
      return generate_patients_from_property(criteria, base_patient) if criteria["property"]

      # Create a coded entry object of the appropriate type given criteria
      # Attach the meta information and necessary code sets to describe the entry
      entry = Object::const_get(criteria["standard_category"].capitalize).new
      entry.description = parse_name_and_category(criteria)[:name]
      entry.codes = {}
      code_sets = self.value_sets.where(:oid => criteria["code_list_id"])
      code_sets.each do |code_set|
        entry.codes[code_set.code_set] = code_set.codes
        entry.specifics = code_set.description # This will do repeated assignments. Unnecessary but isn't harmful. Also gives us best chance to not have nil for specifics
      end

      # Generate all permutations for the values this entry might have
      value_permutations = generate_value_permutations(value)

      # Generate all permutations for temporal values this entry might have
      # For each of these permutations, create a new patient with each value permutation
      temporal_permutations = generate_entry_times(criteria)
      temporal_permutations.each do |time|
        patient = base_patient.clone

        patients << patient
      end

      patients
    end

    def generate_patients_from_property(criteria, base_patient)
      patients = []

      if (criteria["property"] == :age)
        age_permutations = generate_temporal_permutations(criteria["value"], criteria["effective_time"])

        binding.pry
      end

      patients
    end

    # Returns an array of hashes with time, start_time, and end_time keys to create all temporal permutations of an entry.
    #
    # Exactly equal, exactly low, exactly high
    #   Off by 1 second, 1 minute, 1 hour, 1 day, 1 week, 1 month, 1 year
    #     Up to the coarsest available granulatiry (i.e., if the time interval is only a month, we can't test for a year)
    def generate_temporal_permutations(criteria, relative_time)
      permutations = []

      case criteria["type"]
      when "IVL_TS"
        temporal_text = "#{parse_hqmf_time(criteria["width"], relative_time)} " if criteria["width"]

        temporal_text += ">#{parse_hqmf_time_stamp("low", criteria, relative_time)} start" if criteria["low"]
        temporal_text += " and " if criteria["low"] && criteria["high"]
        temporal_text += "<#{parse_hqmf_time_stamp("high", criteria, relative_time)} end" if criteria["high"]
      when "IVL_PQ"
        permutations.concat(generate_time_vector(criteria["low"], criteria["effective_time"])) if criteria["low"]
        permutations.concat(generate_time_vector(criteria["high"])) if criteria["high"]
      end

      temporal_text

      time = Time.now.to_i
      start_time = Time.now.to_i
      end_time = Time.now.to_i

      temporal_permutations << { time: time, start_time: start_time, end_time: end_time }
    end

    def generate_time_vector(criteria, relative_time)
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

    def adjust_time(time, value, unit)

    end

    def generate_value_permutations(criteria)
      value_permutations = []
    end
  end
end