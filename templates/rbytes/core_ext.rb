# Rails core extensions can be used in templates.
# Let's try to load ActiveSupport first and fallback to our custom set of extensions otherwise.
begin
  require "active_support"
  require "active_support/core_ext"
rescue LoadError
  # TODO: Add more extensions
  class ::String
    def parameterize
      downcase.gsub(/[^a-z0-9\-_]+/, '-').gsub(/-{2,}/, '-').gsub(/^-|-$/, '')
    end

    def underscore
      gsub("::", "/").gsub(/([a-z])([A-Z])/, '\1_\2').downcase
    end
  end

  class ::Object
    alias empty? nil?
  end
end
