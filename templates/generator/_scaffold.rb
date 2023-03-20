file "template/_example.rb", <<~CODE
  say "Hey from the included template!"
CODE

file "template/#{name}.rb", <<~CODE
  say "Hey! Let's start withe the #{human_name} installation"
  <%%= include "example" %>
CODE

file "Gemfile", <<~CODE
  # frozen_string_literal: true

  source "https://rubygems.org"

  gem "debug"

  gem "rbytes"

  gem "rake"

  gem "minitest"
  gem "minitest-focus"
  gem "minitest-reporters"

CODE

file "Rakefile", <%= code 'Rakefile' %>
file "README.md", <%= code 'README.md' %>
file ".gitignore", <%= code '.gitignore' %>
