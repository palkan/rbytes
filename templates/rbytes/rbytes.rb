# frozen_string_literal: true

class Rbytes < Thor
  desc "template", "Load and run generator from RailsBytes"
  def template(url)
    puts "Run template from: #{url}"

    # require gems typically used in templates
    require "bundler"

    Base.new.apply(url)
  end

  <%= include "core_ext", indent: 2 %>

  class Base < Thor::Group
    <%= include "rails_application_stub", indent: 4 %>
    <%= include "rails_actions", indent: 4 %>

    include Thor::Actions
    include Rails::Actions

    # Custom methods defined on AppGenerator
    # https://github.com/rails/rails/blob/38275763257221e381cd4e37958ce1413fd0433c/railties/lib/rails/generators/rails/app/app_generator.rb#L558
    def file(*args, &block)
      create_file(*args, &block)
    end
  end
end
