file "test/test_helper.rb", <%= code("test_helper.rb") %>
file "test/template_test.rb", <%= code("template_test.rb") %>
file "test/template/example_test.rb", <%= code("example_test.rb") %>

if needs_rails
  file "test/fixtures/basic_rails_app/config.ru", <%= code "basic_rails_app/config.ru" %>
  file "test/fixtures/basic_rails_app/Gemfile", <%= code "basic_rails_app/Gemfile" %>
  file "test/fixtures/basic_rails_app/Gemfile.lock", <%= code "basic_rails_app/Gemfile.lock" %>
  file "test/fixtures/basic_rails_app/config/environment.rb", <%= code "basic_rails_app/config/environment.rb" %>
  file "test/fixtures/basic_rails_app/config/application.rb", <%= code "basic_rails_app/config/application.rb" %>
  file "test/fixtures/basic_rails_app/config/environments/development.rb", <%= code "basic_rails_app/config/environments/development.rb" %>
  file "test/fixtures/basic_rails_app/config/database.yml", <%= code "basic_rails_app/config/database.yml" %>
end
