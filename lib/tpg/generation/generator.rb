module HQMF
  # The generator will create as many patients as possible to exhaustively test the logic of a given clinical quality measure.
  class Generator
    # TODO - This is a hack and a half. Need a better way to resolve data_criteria from any point in the tree.
    class << self
      attr_accessor :hqmf
      attr_accessor :value_sets
    end
    
    # @param [HQMF::Document] hqmf A model representing the logic of a given HQMF document.
    # @param [Hash] value_sets All of the value sets referenced by this particular HQMF document.
    def initialize(hqmf, value_sets)
      @patients = []
      Generator.hqmf = hqmf
      Generator.value_sets = value_sets
    end
    
    # Generate patients from lists of DataCriteria. This is originally created for QRDA Category 1 validation testing,
    # i.e. a single patient will be generated per measure with an entry for every data criteria involved in the measure.
    # 
    # @param [Hash] measure_needs A hash of measure IDs mapped to a list of all their data criteria.
    # @param [Hash] measure_value_sets A hash of measure IDs mapped to hashes of value sets used by the DataCriteria in measure_needs.
    # @return [Hash] A hash of measure IDs mapped to a Record that includes all the given data criteria (values and times are arbitrary).
    def self.generate_qrda_patients(measure_needs, measure_value_sets)
      return {} if measure_needs.nil?
      
      measure_patients = {}
      measure_needs.each do |measure, all_data_criteria|
        # Prune out all data criteria that create similar entries. Category 1 validation is only checking for ability to access information
        # so to minimize time we only want to include each kind of data once.
        unique_data_criteria = []
        all_data_criteria.each do |data_criteria|
          index = unique_data_criteria.index {|dc| dc.code_list_id == data_criteria.code_list_id && dc.negation_code_list_id == data_criteria.negation_code_list_id && dc.field_values == data_criteria.field_values && dc.status == data_criteria.status}
          unique_data_criteria << data_criteria if index.nil?
        end
        
        # Create a patient that includes an entry for every data criteria included in this measure.
        patient = Generator.create_base_patient
        unique_data_criteria.each do |data_criteria|
          # Ignore data criteria that are really just containers.
          next if data_criteria.derivation_operator.present?
          
          # Generate a random time for this data criteria and apply it to the patient.
          time = Randomizer.randomize_range(patient.birthdate, nil)
          data_criteria.modify_patient(patient, time, measure_value_sets[measure])
        end
        measure_patients[measure] = Generator.finalize_patient(patient)
      end
      
      measure_patients
    end
    
    # Generate patients from an HQMF file and its matching value sets file. These patients are designed to test all
    # paths through the logic of this particular clinical quality measure.
    def generate_patients
      base_patients = [Generator.create_base_patient]
      generated_patients = []
      
      # Gather all available populations. Each kind of population (e.g. IPP, DENOM) can have many multiples (e.g. IPP_1, IPP_2)
      populations = []
      ["IPP", "DENOM", "NUMER", "EXCL", "DENEXCEP"].each do |population|
        i = 1
        populations << population
        while Generator.hqmf.population_criteria("#{population}_#{i}").present? do
          populations << "#{population}_#{i}"
          i += 1
        end
      end

      populations = ["EXCL_1"]

      populations.each do |population|
        criteria = Generator.hqmf.population_criteria(population)
        
        # We don't need to do anything for populations with nothing specified
        next if criteria.nil? || !criteria.preconditions.present?
        criteria.generate(base_patients)  
        
        # Mark the patient we just created with its expected population. Then extend the Record to be augmented by the next population.
        base_patients.collect! do |patient|
          patient.elimination_population = population
          generated_patients.push(Generator.finalize_patient(patient))
          Generator.extend_patient(patient)
        end
      end
      
      generated_patients
    end
    
    # Create a patient with trivial demographic information and no coded entries.
    #
    # @return A Record with a blank slate
    def self.create_base_patient(initial_attributes = nil)
      patient = Record.new
      patient.elimination_population = nil
      patient.elimination_reason = nil
      
      if initial_attributes.nil?
        patient = Randomizer.randomize_demographics(patient)
      else
        initial_attributes.each {|attribute, value| patient.send("#{attribute}=", value)}
      end
      
      patient
    end
    
    # Take an existing patient with some coded entries on them and redefine their trivial demographic information
    #
    # @param [Record] base_patient The patient that we're using as a base to create a new one
    # @return A new Record with an identical medical history to the given patient but new trivial demographic information
    def self.extend_patient(base_patient)
      patient = base_patient.clone()
      Randomizer.randomize_demographics(patient)
    end
    
    # Fill in any missing details that should be filled in on a patient. These include: age, gender, and first name.
    #
    # @param [Record] patient The patient for whom we are about to fill in remaining demographic information.
    # @return A patient with guaranteed complete information necessary for standard formats.
    def self.finalize_patient(patient)
      if patient.birthdate.nil?
        patient.birthdate = Randomizer.randomize_birthdate(patient)
        patient.birthdate = Time.now.to_i
      end
      
      if patient.gender.nil?
        # Set gender
        patient.gender = "F"
        #rand(2) == 0 ? patient.gender = "M" : patient.gender = "F"
        patient.first = Randomizer.randomize_first_name(patient.gender)
      end
      
      patient
    end
    
    #
    #
    # @param [String] type 
    # @return 
    def self.classify_entry(type)
      # The possible matches per patientAPI function can be found in hqmf-parser's README
      case type
      when :allProcedures
        "procedures"
      when :proceduresPerformed
        "procedures"
      when :procedureResults
        "lab_results"
      when :laboratoryTests
        "vital_signs"
      when :allMedications
        "medications"
      when :activeDiagnoses
        "conditions"
      when :inactiveDiagnoses
        "conditions"
      when :resolvedDiagnoses
        "conditions"
      when :allProblems
        "conditions"
      when :allDevices
        "medical_equipment"
      else
        type.to_s
      end
    end
  end
end