# frozen_string_literal: true

require "erb"

module RubyBytes
  class Compiler
    attr_reader :path, :template, :root

    def initialize(path, root: nil)
      @path = path
      raise ArgumentError, "There is no file at the path: #{path}" unless File.file?(path)

      @template = File.read(path)
      @root = root || File.dirname(File.expand_path(path))
    end

    def render(contents = template)
      ERB.new(contents, trim_mode: "<>").result(binding)
    end

    def code(path)
      contents = File.read(resolve_path(path))
      %(ERB.new(
    *[
  <<~'TCODE'
#{contents}
  TCODE
  ], trim_mode: "<>").result(binding))
    end

    def include(path, indent: 0)
      indented(render(File.read(resolve_path(path))), indent)
    end

    def import_template(path, indent: 0)
      indented(self.class.new(File.join(root, path)).render, indent)
    end

    private

    PATH_CANDIDATES = [
      "%{path}",
      "_%{path}",
      "%{path}.rb",
      "_%{path}.rb",
      "%{path}.tt",
      "_%{path}.tt"
    ].freeze

    def resolve_path(path)
      PATH_CANDIDATES.each do |pattern|
        resolved = File.join(root, pattern % {path: path})
        return resolved if File.file?(resolved)
      end

      raise "File not found: #{path}"
    end

    def indented(content, multiplier = 2) # :doc:
      spaces = " " * multiplier
      content.each_line.map { |line| (!line.match?(/\S/)) ? line : "#{spaces}#{line}" }.join
    end
  end
end
