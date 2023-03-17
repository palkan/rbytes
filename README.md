[![Gem Version](https://badge.fury.io/rb/rbytes.svg)](https://rubygems.org/gems/rbytes) [![Build](https://github.com/palkan/rbytes/workflows/Build/badge.svg)](https://github.com/palkan/rbytes/actions)

# Ruby Bytes

Ruby Bytes is a tool to build application templates for Ruby and Rails applications, which helps to:

- Build complex templates consisting of multiple independent components.
- Test templates with ease.

We also provide a [GitHub action](#github-action) to deploy _compiled_ templates to [RailsBytes][].

Templates built with Ruby Bytes can be used with the `rails app:template` command or with a custom [Thor command](#thor-integration) (if you want to use a template in a Rails-less environment).

See examples in the [templates](https://github.com/palkan/rbytes/tree/master/templates) folder. Other noticeable examples are [ruby-on-whales][] and [view_component-contrib][].

## Installation

In your Gemfile:

```ruby
# Gemfile
gem "rbytes"
```

## Writing templates

Ruby Bytes adds partial support to Thor/Rails templates. For that, you can use `#include` and `#render` methods:

```erb
say "Welcome to a custom Rails template!"

<%= include "setup_gems" %>

file "config/initializers/my-gem.rb", <%= code("initializer.rb") %>
```

The `#include` helper simply injects the contents of the partial into the resulting file.

The `#code` method allows you to inject dynamic contents depending on the local variables defined. For example, given the following template and a partial:

```erb
# _anycable.yml.tt
development:
  broadcast_adapter: <%= cable_adapter %>

# template.rb
cable_adapter = ask? "Which AnyCable pub/sub adapter do you want to use?"

file "config/anycable.yml", <%= code("anycable.yml") %>
```

The compiled template will like like this:

```erb
cable_adapter = ask? "Which AnyCable pub/sub adapter do you want to use?"

file "config/anycable.yml", ERB.new(
  *[
  <<~'CODE'
    development:
      broadcast_adapter: <%= cable_adapter %>
  CODE
  ], trim_mode: "<>").result(binding)
```

**NOTE:** By default, we assume that partials are stored next to the template's entrypoint. Partials may have "_" prefix and ".rb"/".tt" suffixes.

### Compiling templates

You can compile a template by using the `RubyBytes::Compiler` class:

```ruby
RubyBytes::Compiler.new(path_to_template).render #=> compiled string
```

You can also specify a custom partials directory:

```ruby
RubyBytes::Compiler.new(path_to_template, root: partials_directory).render
```

Here is a one-liner:

```sh
ruby -r rbytes -e "puts RubyBytes::Compiler.new(<path>).render"
```

### Testing

We provide a Minitest integration to test your templates.

Here is an example usage:

```ruby
require "ruby_bytes/test_case"

class TemplateTest < RubyBytes::TestCasee
  # Specify root path for your template (for partials lookup)
  root File.join(__dir__, "../template")

  # You can test partials in isolation by declaring a custom template
  template <<~RUBY
    say "Hello from some partial"
    <%= include "some_partial" %>
  RUBY

  def test_some_partial
    run_generator do |output|
      assert_file "application.rb"

      assert_file_contains(
        "application.rb",
        <<~CODE
          module Rails
            class << self
              def application
        CODE
      )

      refute_file_contains(
        "application.rb",
        "Nothing"
      )

      assert_line_printed output, "Hello from some partial"
    end
  end
end
```

If you use prompt in your templates, you can prepopulate standard input:

```ruby
class TemplateTest < RubyBytes::TestCasee
  # Specify root path for your template (for partials lookup)
  root File.join(__dir__, "../template")

  # You can test partials in isolation by declaring a custom template
  template <<~RUBY
    say "Hello from some partial"
    if yes?("Do you write tests?")
      say "Gut"
    else
      say "Why not?"
    end
  RUBY

  def test_prompt_yes
    run_generator(input: ["y"]) do |output|
      assert_line_printed output, "Gut"
    end
  end

  def test_prompt_no
    run_generator(input: ["n"]) do |output|
      assert_line_printed output, "Why not?"
    end
  end
end
```

## Thor integration

We provide a custom Thor command, which can be used to apply templates (similar to `rails app:template`).

- First, make sure you have Thor installed (`gem install thor`).
- Install `rbytes:template` command by running:

```sh
thor install https://railsbytes.com/script/zNPsdN
```

Now you can execute Rails (and non-Rails) templates using Thor:

```sh
# hello world template
$ thor rbytes:template https://railsbytes.com/script/x7msKX

Run template from: https://railsbytes.com/script/x7msKX
  apply  https://railsbytes.com/script/x7msKX
hello world from https://railsbytes.com 👋
```

## GitHub action

You can use our GitHub action to deploy your templates to RailsBytes.

Here is an example:

```yml
name: Publish

on:
  push:
    tags:
      - v*
  workflow_dispatch:

jobs:
  publish:
    uses: palkan/rbytes/.github/workflows/railsbytes.yml@master
    with:
      template: templates/my-template.rb
    secrets:
      RAILS_BYTES_ACCOUNT_ID: "${{ secrets.RAILS_BYTES_ACCOUNT_ID }}"
      RAILS_BYTES_TOKEN: "${{ secrets.RAILS_BYTES_TOKEN }}"
      RAILS_BYTES_TEMPLATE_ID: "${{ secrets.RAILS_TEMPLATE_ID }}"
```

## Contributing

Bug reports and pull requests are welcome on GitHub at [https://github.com/palkan/rbytes](https://github.com/palkan/rbytes).

## Credits

This gem is generated via [new-gem-generator](https://github.com/palkan/new-gem-generator).

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

[RailsBytes]: https://railsbytes.com
[ruby-on-whales]: https://github.com/evilmartians/ruby-on-whales
[view_component-contrib]: https://github.com/palkan/view_component-contrib
