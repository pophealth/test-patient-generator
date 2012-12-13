require 'test_helper'

# These tests are very coarse grained because they are testing randomizing functionality.
# Largely these unit tests will verify that we are getting at least some information, but does not exhaustively test that the random values are appropriate.
class RandomizerTest < MiniTest::Unit::TestCase
  def test_randomize_demographics
    patient = Record.new
    HQMF::Randomizer.randomize_demographics(patient)

    expected_fields = [:race, :ethnicity, :languages, :last, :medical_record_number]
    expected_fields.each do |field|
      refute_nil patient.send(field)
    end
  end

  def test_randomize_race_and_ethnicity
    assert_equal '2076-8', HQMF::Randomizer.randomize_race_and_ethnicity(0)[:race]
    assert_equal '1002-5', HQMF::Randomizer.randomize_race_and_ethnicity(2)[:race]
    assert_equal '2028-9', HQMF::Randomizer.randomize_race_and_ethnicity(11)[:race]
    assert_equal '2054-5', HQMF::Randomizer.randomize_race_and_ethnicity(59)[:race]
    assert_equal '2106-3', HQMF::Randomizer.randomize_race_and_ethnicity(185)[:race]
    assert_equal '2106-3', HQMF::Randomizer.randomize_race_and_ethnicity(348)[:race]
    assert_equal '2131-1', HQMF::Randomizer.randomize_race_and_ethnicity(985)[:race]
  end

  def test_randomize_language
    assert_equal 'en-US', HQMF::Randomizer.randomize_language(0)
    assert_equal 'es-US', HQMF::Randomizer.randomize_language(803)
    assert_equal 'fr-US', HQMF::Randomizer.randomize_language(926)
    assert_equal 'it-US', HQMF::Randomizer.randomize_language(933)
    assert_equal 'pt-US', HQMF::Randomizer.randomize_language(936)
    assert_equal 'de-US', HQMF::Randomizer.randomize_language(939)
    assert_equal 'el-US', HQMF::Randomizer.randomize_language(943)
    assert_equal 'ru-US', HQMF::Randomizer.randomize_language(944)
    assert_equal 'pl-US', HQMF::Randomizer.randomize_language(947)
    assert_equal 'fa-US', HQMF::Randomizer.randomize_language(949)
    assert_equal 'zh-US', HQMF::Randomizer.randomize_language(950)
    assert_equal 'ja-US', HQMF::Randomizer.randomize_language(959)
    assert_equal 'ko-US', HQMF::Randomizer.randomize_language(961)
    assert_equal 'vi-US', HQMF::Randomizer.randomize_language(965)
    assert_equal 'sgn-US', HQMF::Randomizer.randomize_language(969)
    assert HQMF::Randomizer.randomize_language(970).include? "-US"
  end

  def test_randomize_first_name
    refute_nil HQMF::Randomizer.randomize_first_name("M")
    refute_nil HQMF::Randomizer.randomize_first_name("F")
  end

  def test_randomize_last_name
    refute_nil HQMF::Randomizer.randomize_last_name
  end

  def test_randomize_address
    address = HQMF::Randomizer.randomize_address
    address = JSON.parse(address)
    expected = ["street", "city", "state", "postalCode"]

    assert_equal address.size, expected.size
    address.each do |key, value|
      assert expected.include? key
      refute_nil value
    end
  end

  def test_randomize_birthdate
    refute_nil HQMF::Randomizer.randomize_birthdate(Record.new)
  end

  def test_randomize_range
    range = HQMF::Randomizer.randomize_range(nil, nil)
    refute_nil range.low
    refute_nil range.high

    now = Time.at(1234567890)
    later = now + (60 * 60 * 24 * 7)
    range = HQMF::Randomizer.randomize_range(now, later)
    
    assert now.to_i <= range.low.to_seconds
    assert later.to_i >= range.high.to_seconds
  end

  def test_n_between
    betweens = HQMF::Randomizer.n_between(0, 100)
    betweens = JSON.parse(betweens)

    refute_empty betweens
  end

  def test_between
    between = HQMF::Randomizer.between(0, 100)
    refute_nil between
    assert between >= 0
    assert between <= 100
  end

  def test_percent
    refute_nil HQMF::Randomizer.percent(50)
    refute HQMF::Randomizer.percent(-1)
  end
end