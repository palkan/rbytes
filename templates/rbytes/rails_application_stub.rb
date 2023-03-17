# Stub `Rails.application` to have a correct application name
module Rails
  class << self
    def application
      return unless File.exist?("config/application.rb")

      File.read("config/application.rb").then do |contents|
        contents.match(/^module (\S+)\s*$/)
      end.then do |matches|
        next unless matches

        Module.new.then do |mod|
          Object.const_set(matches[1], mod)
          app_class = Class.new
          mod.const_set(:Application, app_class)
          app_class.new
        end
      end
    end
  end
end
