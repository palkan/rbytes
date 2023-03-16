# Stub `Rails.application` to have a correct application name
module Rails
  class << self
    def application
      return unless File.exist?("config/application.rb")

      File.read("config/application.rb").then do |contents|
        contents.match(/^module (\S+)\s+$/)
      end.then do |matches|
        next unless matches

        Module.new(matches[1]).tap do |mod|
          mod.const_set(:Application, Class.new)
        end
      end
    end
  end
end
