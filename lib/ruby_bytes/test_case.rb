# frozen_string_literal: true

require "minitest"
require "fileutils"
require "stringio"
require "thor"

require "ruby_bytes/thor"

module RubyBytes
  class TestCase < Minitest::Test
    TMP_DIR = File.join(Dir.pwd, "tmp", "rbytes_test")

    FileUtils.rm_rf(TMP_DIR) if File.directory?(TMP_DIR)
    FileUtils.mkdir_p(TMP_DIR)

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

      def destination_root(val = nil) = val ? @destination_root = File.expand_path(val) : (@destination_root || TMP_DIR)

      def root(val = nil) = val ? @root = File.expand_path(val) : @root

      def template(contents)
        @template_contents = contents
      end
    end

    def setup
    end

    def teardown
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
        Rbytes::Base.new(
          [TMP_DIR], {}, {destination_root: self.class.destination_root}
        ).apply("current_template.rb")
        yield $stdout.string
      ensure
        $stdout = original_stdout
        $stdin = original_stdin
        $rbytes_testing = false
      end
    end

    def assert_line_printed(io, line)
      lines = io.lines

      assert lines.any? { _1.include?(line) }, "Expected to print line: #{line}. Got: #{io}"
    end

    def assert_file_contains(path, body)
      fullpath = File.join(self.class.destination_root, path)
      assert File.file?(fullpath), "File not found: #{path}"

      actual = File.read(fullpath)
      assert_includes actual, body
    end

    def assert_file(path)
      fullpath = File.join(self.class.destination_root, path)
      assert File.file?(fullpath), "File not found: #{path}"
    end

    def refute_file_contains(path, body)
      fullpath = File.join(self.class.destination_root, path)
      assert File.file?(fullpath), "File not found: #{path}"

      actual = File.read(fullpath)
      refute_includes actual, body
    end
  end
end
