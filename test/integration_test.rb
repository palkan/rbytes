# frozen_string_literal: true

require "test_helper"

class BasicTest < RubyBytes::TestCase
  template <<~RUBY
    say "Hello world!"
  RUBY

  def test_hello_world
    run_generator do |output|
      assert_line_printed(
        output,
        "Hello world!"
      )
    end
  end
end

class CodeTest < RubyBytes::TestCase
  root File.join(__dir__, "../templates/rbytes")

  template <<~RUBY
    # Some stuff for Rails.application to work
    file "application.rb", <%= code("rails_application_stub.rb") %>
  RUBY

  def test_code_snippets
    run_generator do |output|
      assert_file_contains(
        "application.rb",
        <<~CODE
          module Rails
            class << self
              def application
        CODE
      )
    end
  end
end

class PartialLookupTest < RubyBytes::TestCase
  destination_root File.join(TMP_DIR, "custom")

  template <<~RUBY
    <%= include "say_ruby" %>
  RUBY

  def setup
    File.write(
      File.join(TMP_DIR, "_say_ruby.tt"),
      <<~RUBY
        file "test.rb", "puts '\#{RUBY_VERSION}'"

        say "Ruby version is: \#{RUBY_VERSION}"
      RUBY
    )
  end

  def test_include_partials
    run_generator do |output|
      assert_line_printed output, "Ruby version is: #{RUBY_VERSION}"
      assert_file "test.rb"
      refute_file_contains "test.rb", "RUBY_VERSION"
    end
  end
end

class PromptTest < RubyBytes::TestCase
  template <<~RUBY
    if yes?("Mochtest du etwas trinken?")
      puts "Gut"
    else
      puts "Ciao"
    end
  RUBY

  def test_prompt_yes
    run_generator(input: ["y"]) do |output|
      assert_line_printed(
        output,
        "Gut"
      )
    end
  end

  def test_prompt_no
    run_generator(input: ["n"]) do |output|
      assert_line_printed(
        output,
        "Ciao"
      )
    end
  end
end
