# frozen_string_literal: true

require "rbytes"
require "optparse"

module RubyBytes
  class CLI
    COMMANDS = %w[
      compile
      publish
    ].freeze

    def run(command, *args)
      raise ArgumentError, "Unknown command: #{command}\nAvailable commands are: #{COMMANDS.join(", ")}\nRuby Bytes: v#{RubyBytes::VERSION}" unless COMMANDS.include?(command)

      public_send(command, *args)
    end

    def compile(*args)
      root = nil # rubocop:disable Lint/UselessAssignment

      path, args = *args

      OptionParser.new do |o|
        o.on "-v", "--version", "Print version and exit" do |_arg|
          $stdout.puts "Ruby Bytes: v#{RubyBytes::VERSION}"
          exit(0)
        end

        o.on "--root [DIR]", "Location of partial template files" do
          raise ArgumentError, "Directory not found: #{_1}" unless File.directory?(_1)
          root = _1
        end

        o.on_tail "-h", "--help", "Show help" do
          $stdout.puts <<~USAGE
            rbytes compile PATH [options]

            Options:
                --root DIR Location of partial template files
          USAGE

          exit(0)
        end
      end.parse!(args || [])

      raise ArgumentError, "File not found: #{path}" unless File.file?(path)

      $stdout.puts Compiler.new(path, root: root).render
    end

    def publish(*args)
      root = nil # rubocop:disable Lint/UselessAssignment

      path, args = *args

      OptionParser.new do |o|
        o.on "-v", "--version", "Print version and exit" do |_arg|
          $stdout.puts "Ruby Bytes: v#{RubyBytes::VERSION}"
          exit(0)
        end

        o.on "--root [DIR]", "Location of partial template files" do
          raise ArgumentError, "Directory not found: #{_1}" unless File.directory?(_1)
          root = _1
        end

        o.on_tail "-h", "--help", "Show help" do
          $stdout.puts <<~USAGE
            rbytes publish PATH [options]

            Options:
                --root DIR Location of partial template files
          USAGE

          exit(0)
        end
      end.parse!(args || [])

      raise ArgumentError, "File not found: #{path}" unless File.file?(path)

      contents = Compiler.new(path, root: root).render

      Publisher.new.call(contents)

      $stdout.puts "Published successfully ✅"
    end
  end
end
