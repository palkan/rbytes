[![Gem Version](https://badge.fury.io/rb/rbytes.svg)](https://rubygems.org/gems/rbytes) [![Build](https://github.com/palkan/rbytes/workflows/Build/badge.svg)](https://github.com/palkan/rbytes/actions)

# Ruby Bytes

Ruby Bytes is a tool to build application templates for Ruby and Rails applications, which helps to:

- Build complex templates consisting of multiple independent components.
- Test templates with ease.

We also provide a GitHub action to deploy _compiled_ templates to [RailsBytes][].

Templates built with Ruby Bytes can be used with the `rails app:template` command or with a custom [Thor command](#thor-integration) (if you want to use a template in a Rails-less environment)

## Installation

In your Gemfile:

```ruby
# Gemfile
gem "rbytes"
```

## Building templates

### Testing

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

## Contributing

Bug reports and pull requests are welcome on GitHub at [https://github.com/palkan/rbytes](https://github.com/palkan/rbytes).

## Credits

This gem is generated via [new-gem-generator](https://github.com/palkan/new-gem-generator).

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

[RailsBytes]: https://railsbytes.com
