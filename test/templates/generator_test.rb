# frozen_string_literal: true

require "test_helper"

class GeneratorTest < RubyBytes::TestCase
  root File.join(__dir__, "../../templates/generator")

  def test_compilation
    assert RubyBytes::Compiler.new(File.join(__dir__, "../../templates/generator/generator.rb")).render
  end

  class DetailsTest < GeneratorTest
    template <<~'CODE'
      <%= include "details" %>
      say "NAME=#{name}"
      say "HUMAN_NAME=#{human_name}"
      say "RAILS=#{needs_rails}"
    CODE

    def test_name
      run_generator(input: ["my-plugin", "", "y"]) do |output|
        assert_line_printed(
          output,
          "NAME=my-plugin"
        )
        assert_line_printed(
          output,
          "HUMAN_NAME=My Plugin"
        )
        assert_line_printed(
          output,
          "RAILS=true"
        )
      end
    end
  end

  class ScaffoldTest < GeneratorTest
    template <<~'CODE'
      name = "rbytes-template"
      human_name = "Ruby Bytes"
      needs_rails = true
      <%= include "scaffold" %>
    CODE

    def test_scaffold
      run_generator do
        assert_file "template/rbytes-template.rb"
        assert_file "template/_example.rb"
        assert_file "Gemfile"
        assert_file "README.md"
        assert_file "Rakefile"
        assert_file_contains "template/rbytes-template.rb", "Let's start withe the Ruby Bytes installation"
        assert_file_contains "README.md", "bin/rails app:template LOCATION="
      end
    end
  end

  class TestingWithotRailsTest < GeneratorTest
    template <<~'CODE'
      name = "rbytes-template"
      needs_rails = false
      <%= include "testing" %>
    CODE

    def test_testing_without_rails
      run_generator do
        assert_file "test/test_helper.rb"
        assert_file "test/template_test.rb"
        assert_file "test/template/example_test.rb"
        refute_file "test/fixtures/basic_rails_app/config/application.rb"
      end
    end
  end

  class TestingWithRailsTest < GeneratorTest
    template <<~'CODE'
      name = "rbytes-template"
      needs_rails = true
      <%= include "testing" %>
    CODE

    def test_testing_with_rails
      run_generator do
        assert_file "test/test_helper.rb"
        assert_file "test/template_test.rb"
        assert_file "test/template/example_test.rb"
        assert_file "test/fixtures/basic_rails_app/config/application.rb"
        assert_file "test/fixtures/basic_rails_app/config.ru"
        assert_file "test/fixtures/basic_rails_app/Gemfile"
        assert_file "test/fixtures/basic_rails_app/Gemfile.lock"
      end
    end
  end

  class CITest < GeneratorTest
    template <<~'CODE'
      name = "rbytes-template"
      <%= include "ci" %>
    CODE

    def test_ci_yes
      run_generator(input: ["y"]) do
        assert_file ".github/workflows/test.yml"
        assert_file ".github/workflows/publish.yml"
      end
    end

    def test_ci_no
      run_generator(input: ["n"]) do
        refute_file ".github/workflows/test.yml"
        refute_file ".github/workflows/publish.yml"
      end
    end
  end
end
