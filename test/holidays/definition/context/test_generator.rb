require File.expand_path(File.dirname(__FILE__)) + '/../../../test_helper'

require 'holidays/definition/context/generator'

class GeneratorTests < Test::Unit::TestCase
  def setup
    @generator = Holidays::Definition::Context::Generator.new
  end

  def test_parse_definition_files_raises_error_if_argument_is_nil
    assert_raises ArgumentError do
      @generator.parse_definition_files(nil)
    end
  end

  def test_parse_definition_files_raises_error_if_files_are_empty
    assert_raises ArgumentError do
      @generator.parse_definition_files([])
    end
  end

  def test_parse_definition_files_correctly_parse_regions
    files = ['test/data/test_single_custom_holiday_defs.yaml']
    regions, rules_by_month, custom_methods, tests = @generator.parse_definition_files(files)

    assert_equal [:custom_single_file], regions
  end

  def test_parse_definitions_files_correctly_parse_rules_by_month
    files = ['test/data/test_single_custom_holiday_defs.yaml']
    regions, rules_by_month, custom_methods, tests = @generator.parse_definition_files(files)

    expected_rules_by_month = {
      6 => [
        {
          :mday    => 20,
          :name    => "Company Founding",
          :regions => [:custom_single_file]
        }
      ]
    }

    assert_equal expected_rules_by_month, rules_by_month
  end

  def test_parse_definition_files_correctly_parse_custom_methods
    files = ['test/data/test_single_custom_holiday_defs.yaml']
    regions, rules_by_month, custom_methods, tests = @generator.parse_definition_files(files)

    expected_custom_methods = {}
    assert_equal expected_custom_methods, custom_methods
  end

  def test_parse_definition_files_correctly_parse_tests
    files = ['test/data/test_single_custom_holiday_defs.yaml']
    regions, rules_by_month, custom_methods, tests = @generator.parse_definition_files(files)

    expected_tests = [[
        "{Date.civil(2013,6,20) => 'Company Founding'}.each do |date, name|\n  assert_equal name, (Holidays.on(date, :custom_single_file)[0] || {})[:name]\nend"
    ]]

    assert_equal expected_tests, tests
  end

  def test_generate_definition_source_correctly_generate_module_src
    files = ['test/data/test_single_custom_holiday_defs.yaml']
    regions, rules_by_month, custom_methods, tests = @generator.parse_definition_files(files)
    module_src, test_src = @generator.generate_definition_source("test", files, regions, rules_by_month, custom_methods, tests)

    expected_module_src = "# encoding: utf-8\nmodule Holidays\n  # This file is generated by the Ruby Holidays gem.\n  #\n  # Definitions loaded: test/data/test_single_custom_holiday_defs.yaml\n  #\n  # To use the definitions in this file, load it right after you load the\n  # Holiday gem:\n  #\n  #   require 'holidays'\n  #   require 'generated_definitions/test'\n  #\n  # All the definitions are available at https://github.com/alexdunae/holidays\n  module TEST # :nodoc:\n    def self.defined_regions\n      [:custom_single_file]\n    end\n\n    def self.holidays_by_month\n      {\n              6 => [{:mday => 20, :name => \"Company Founding\", :regions => [:custom_single_file]}]\n      }\n    end\n  end\n\n\nend\n\nHolidays.merge_defs(Holidays::TEST.defined_regions, Holidays::TEST.holidays_by_month)\n"

    assert_equal expected_module_src, module_src
  end

  def test_generate_definition_source_correctly_genrate_test_src
    files = ['test/data/test_single_custom_holiday_defs.yaml']
    regions, rules_by_month, custom_methods, tests = @generator.parse_definition_files(files)
    module_src, test_src = @generator.generate_definition_source("test", files, regions, rules_by_month, custom_methods, tests)

    expected_test_src = "# encoding: utf-8\nrequire File.expand_path(File.dirname(__FILE__)) + '/../test_helper'\n\n# This file is generated by the Ruby Holiday gem.\n#\n# Definitions loaded: test/data/test_single_custom_holiday_defs.yaml\nclass TestDefinitionTests < Test::Unit::TestCase  # :nodoc:\n\n  def test_test\n{Date.civil(2013,6,20) => 'Company Founding'}.each do |date, name|\n  assert_equal name, (Holidays.on(date, :custom_single_file)[0] || {})[:name]\nend\n  end\nend\n"

    assert_equal expected_test_src, test_src
  end
end
