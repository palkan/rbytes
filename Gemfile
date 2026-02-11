# frozen_string_literal: true

source "https://rubygems.org"

gem "debug", platform: :mri

gemspec

gem "bubbletea"
gem "lipgloss"
gem "bubbles"
gem "gum"
gem "huh", github: "marcoroth/huh-ruby"

eval_gemfile "gemfiles/rubocop.gemfile"

local_gemfile = "#{File.dirname(__FILE__)}/Gemfile.local"

if File.exist?(local_gemfile)
  eval(File.read(local_gemfile)) # rubocop:disable Security/Eval
end
