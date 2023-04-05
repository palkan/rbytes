[![Gem Version](https://badge.fury.io/rb/rbytes.svg)](https://rubygems.org/gems/rbytes) [![Build](https://github.com/palkan/rbytes/workflows/Build/badge.svg)](https://github.com/palkan/rbytes/actions)

# Ruby Bytes

Ruby Bytes is a tool to build application templates for Ruby and Rails applications, which helps to:

- Build complex templates consisting of multiple independent components.
- Test templates with ease.
- Install application templates without Rails.
- Publish templates to [RailsBytes][].

We also provide a [GitHub action](#github-action) to compile and deploy templates continuously.

> 📖 Read more about Ruby Bytes and application templates in the [Ruby Bytes, or generating standalone generators](https://evilmartians.com/chronicles/ruby-bytes-or-generating-standalone-generators) post.

## Examples

- [ruby-on-whales][]
- [view_component-contrib][]
- [rubocoping][]

See also examples in the [templates](https://github.com/palkan/rbytes/tree/master/templates) folder.

## Installation

To install templates, install the `rbytes` executable via the gem:

```sh
gem install rbytes
```

For templates development, add `rbytes` to your Gemfile or gemspec:

```ruby
# Gemfile
gem "rbytes"
```

## Installing templates

You can use `rbytes install <url>` similarly to `rails app:template` but without needing to install Rails. It's useful if you want to use a template in a Rails-less environment.

Usage example:

```sh
$ rbytes install https://railsbytes.com/script/x7msKX

Run template from: https://railsbytes.com/script/x7msKX
  apply  https://railsbytes.com/script/x7msKX
hello world from https://railsbytes.com 👋
```

**IMPORTANT**: Not all templates from RailsBytes may be supported as of yet. Please, let us know if you find incompatibilities with `rails app:template`, so we can fix them.

You can also install Ruby Bytes as a plugin for Thor (see [Thor integration](#thor-integration)).

## Writing templates

The quickest way to get started with using Ruby Bytes to build templates is to use our generator to create a project:

```sh
$ rbytes install https://railsbytes.com/script/V2GsbB

...
```

### Splitting template into partials

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

The compiled template will look like this:

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

**NOTE:** By default, we assume that partials are stored next to the template's entry-point. Partials may have the "_" prefix and ".rb" or ".tt" suffixes.

### Compiling templates

You can compile a template by using the `rbytes` executable:

```sh
$ rbytes compile path/to/template

<compiled template>
```

You can also specify a custom partials directory:

```sh
rbytes compile path/to/template --root=path/to/partials
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

## Publishing manually

You can use the `rbytes publish` command to compile and publish a template to RailsBytes:

```sh
RAILS_BYTES_ACCOUNT_ID=aaa \
RAILS_BYTES_TOKEN=bbb \
RAILS_BYTES_TEMPLATE_ID=ccc \
rbytes publish path/to/template
```

## Contributing

Bug reports and pull requests are welcome on GitHub at [https://github.com/palkan/rbytes](https://github.com/palkan/rbytes).

## Credits

This gem is generated via [`newgem` template](https://github.com/palkan/newgem) by [@palkan](https://github.com/palkan).

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

[RailsBytes]: https://railsbytes.com
[ruby-on-whales]: https://github.com/evilmartians/ruby-on-whales
[view_component-contrib]: https://github.com/palkan/view_component-contrib
[rubocoping]: https://github.com/evilmartians/rubocoping-generator
