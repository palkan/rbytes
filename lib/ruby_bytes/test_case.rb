# frozen_string_literal: true

require "minitest"
require "fileutils"
require "stringio"
require "thor"

require "ruby_bytes/thor"

module RubyBytes
  class TestCase < Minitest::Test
    TMP_DIR = File.join(Dir.pwd, "tmp", "rbytes_test")

    Rbytes::Base.source_paths << TMP_DIR

    # Patch Thor::LineEditor to use Basic in tests
    $rbytes_testing = false

    Thor::LineEditor.singleton_class.prepend(Module.new do
      def best_available
        return super unless $rbytes_testing

        Thor::LineEditor::Basic
      end
    end)

    class << self
      attr_reader :template_contents

      def destination_root(val = nil)
        if val
          @destination_root = val
        end

        return @destination_root if instance_variable_defined?(:@destination_root)

        @destination_root =
          if superclass.respond_to?(:destination_root)
            superclass.destination_root
          else
            TMP_DIR
          end
      end

      def root(val = nil)
        if val
          @root = val
        end

        return @root if instance_variable_defined?(:@root)

        @root =
          if superclass.respond_to?(:root)
            superclass.root
          end
      end

      # Set the path to dummy app.
      # Dummy app is copied to the temporary directory for every run
      # and set as a destination root.
      def dummy_app(val = nil)
        if val
          @dummy_app = val
        end

        return @dummy_app if instance_variable_defined?(:@dummy_app)

        @dummy_app =
          if superclass.respond_to?(:dummy_app)
            superclass.dummy_app
          end
      end

      def template(contents)
        @template_contents = contents
      end
    end

    attr_accessor :destination

    def setup
      FileUtils.rm_rf(TMP_DIR) if File.directory?(TMP_DIR)
      FileUtils.mkdir_p(TMP_DIR)
    end

    def prepare_dummy
      # Then, copy the dummy app if any
      dummy = self.class.dummy_app
      return unless dummy

      return if @dummy_prepared

      raise ArgumentError, "Dummy app must be a directory" unless File.directory?(dummy)

      tmp_dummy_path = File.join(TMP_DIR, "dummy")
      FileUtils.rm_rf(tmp_dummy_path) if File.directory?(tmp_dummy_path)
      FileUtils.cp_r(dummy, tmp_dummy_path)
      self.destination = tmp_dummy_path

      if block_given?
        Dir.chdir(tmp_dummy_path) { yield }
      end

      @dummy_prepared = true
    end

    def run_generator(input: [])
      # First, compile the template (if not yet)
      path = File.join(TMP_DIR, "current_template.rb")

      if File.file?(path)
        File.delete(path)
      end

      File.write(path, "")

      rendered = Compiler.new(path, root: self.class.root).render(self.class.template_contents)
      File.write(path, rendered)

      self.destination = self.class.destination_root

      prepare_dummy

      original_stdout = $stdout
      original_stdin = $stdin

      if input.size > 0
        $rbytes_testing = true

        io = StringIO.new
        input.each { io.puts(_1) }
        io.rewind
        $stdin = io
        $stdin.sync = true
      end

      $stdout = StringIO.new
      $stdout.sync = true

      begin
        Dir.chdir(destination) do
          Rbytes::Base.new(
            [destination], {}, {destination_root: destination}
          ).apply("current_template.rb")
        end
        yield $stdout.string if block_given?
      ensure
        $stdout = original_stdout
        $stdin = original_stdin
        $rbytes_testing = false
        @dummy_prepared = false
      end
    end

    def assert_line_printed(io, line)
      lines = io.lines

      assert lines.any? { _1.include?(line) }, "Expected to print line: #{line}. Got: #{io}"
    end

    def assert_file_contains(path, body)
      fullpath = File.join(destination, path)
      assert File.file?(fullpath), "File not found: #{path}"

      actual = File.read(fullpath)
      assert_includes actual, body
    end

    def assert_file(path)
      fullpath = File.join(destination, path)
      assert File.file?(fullpath), "File not found: #{path}"
    end

    def refute_file(path)
      fullpath = File.join(destination, path)
      refute File.file?(fullpath), "File must not exist: #{path}"
    end

    def refute_file_contains(path, body)
      fullpath = File.join(destination, path)
      assert File.file?(fullpath), "File not found: #{path}"

      actual = File.read(fullpath)
      refute_includes actual, body
    end
  end
end
