module TPG
  module Generation
    class Traverser
      # Returns an array of Records tailored to test the logic of this measure
      def generate_patients
        patients = []
        base_patient = Record.new

        # Attach the reason each patient was dropped from a population criteria
        #  e.g. "denominator", "missing: medication pneumococcal vaccine all ages "
        base_patient.final_destination = nil
        base_patient.final_destination_reason = nil

        # We start with an empty patient and will build out many from each population.
        # At each step, we grow our base patient to represent the tree we've traversed so far.
        # Each recursive step will return an array that we merge into our patients.
        patients.concat(generate_patients_from_preconditions(self.population_criteria["IPP"], base_patient))

        # For every IPP base patient who potentially qualifies for the denominator, continue to recursively define all permutations
        # patients.each do |patient|
        #       if patient.final_destination.nil?
        #         patients.concat(generate_patients_from_preconditions(self.population_criteria["DENOM"], patient))
        #       end
        #     end

        # For every DENOM base patient who potentially qualifies for the numerator, continue to recursively define all permutations
        # patients.each do |patient|
        #       if patient.final_destination.nil?
        #         patients.concat(generate_patients_from_preconditions(self.population_criteria["NUMER"], patient))
        #       end
        #     end

        patients
      end
      
      def remove_category_from_name(name, category)
        return name unless category
        last_word_of_category = category.split.last.gsub(/_/,' ')
        name =~ /#{last_word_of_category}. (.*)/i # The portion after autoformatted text, i.e. actual name (e.g. pneumococcal vaccine)
        $1
      end

      # This is a helper for parse_hqmf_preconditions.
      # Return a human readable title and category for a given data criteria
      def parse_hqmf_data_criteria(criteria)
        fragment = {}

        name_and_category = parse_name_and_category(criteria)
        name = name_and_category[:name]
        category = name_and_category[:category]

        if criteria["value"] # Some exceptions have the value key. Bump it forward so criteria is idenical to the format of usual coded entries
          criteria = criteria["value"]
        else # Find the display name as per usual for the coded entry
          criteria = criteria["effective_time"] if criteria["effective_time"]
        end

        measure_period["name"] = "the measure period"
        temporal_text = parse_hqmf_time(criteria, measure_period)
        title = "#{name} #{temporal_text}"

        fragment["title"] = title
        fragment["category"] = category.gsub(/_/,' ') if category
        fragment
      end

      # Takes criteria and does a best effort to produce the name and category that briefly describes the precondition
      # Returns a hash with name and category keys
      def parse_name_and_category(criteria)
        name_and_category = {}

        name = criteria["property"].to_s
        category = criteria["standard_category"]
        criteria_orig = criteria
        # QDS data type is most specific, so use it if available. Otherwise use the standard category.
        category_mapping = { "individual_characteristic" => "patient characteristic" }
        if criteria["qds_data_type"]
          category = criteria["qds_data_type"].gsub(/_/, " ") # "medication_administered" = "medication administered"
        elsif category_mapping[category]
          category = category_mapping[category]
        end

        name = remove_category_from_name(criteria["title"], category)

        { name: name, category: category}
      end

      ####################################################################################################################################
      # Patient Generation - TODO move this into a proper separate project. Keeping it here for an easy and quick start
      # 
      # This process is going to look very similar to the parameter at first while exploring to see what's tractable
      ####################################################################################################################################

      def generate_patients_from_preconditions(criteria, base_patient)
        patients = []

        if criteria["conjunction?"] # We're at the top of the tree
          criteria["preconditions"].each do |precondition|
            patients.concat(generate_patients_from_preconditions(precondition, base_patient))
          end
        else # We're somewhere in the middle
          conjunction = criteria["conjunction_code"]
          criteria["preconditions"].each do |precondition|
            if precondition["reference"] # We've hit a leaf node - This is a data criteria reference
              patients.concat(generate_patients_from_data_criteria(data_criteria[precondition["reference"]], base_patient))
            else # There are additional layers below
              patients.concat(generate_patients_from_preconditions(precondition, base_patient))
            end
          end if criteria["preconditions"]
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
end