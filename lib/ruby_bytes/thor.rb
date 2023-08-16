# frozen_string_literal: true

class Rbytes < Thor
  desc "template", "Load and run generator from RailsBytes"
  def template(url)
    puts "Run template from: #{url}"

    # require gems typically used in templates
    require "bundler"

    Base.new.apply(url)
  end

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


  class Base < Thor::Group
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

        # Copied from https://github.com/rails/rails/blob/38275763257221e381cd4e37958ce1413fd0433c/railties/lib/rails/generators/actions.rb
    module Rails
      module Actions
        # Adds an entry into +Gemfile+ for the supplied gem.
        #
        #   gem "rspec", group: :test
        #   gem "technoweenie-restful-authentication", lib: "restful-authentication", source: "http://gems.github.com/"
        #   gem "rails", "3.0", git: "https://github.com/rails/rails"
        #   gem "RedCloth", ">= 4.1.0", "< 4.2.0"
        #   gem "rspec", comment: "Put this comment above the gem declaration"
        def gem(*args, **options)
          name, *versions = args

          # Set the message to be shown in logs. Uses the git repo if one is given,
          # otherwise use name (version).
          parts, message = [quote(name)], name.dup

          # Output a comment above the gem declaration.
          comment = options.delete(:comment)

          if versions = versions.any? ? versions : options.delete(:version)
            _versions = Array(versions)
            _versions.each do |version|
              parts << quote(version)
            end
            message << " (#{_versions.join(", ")})"
          end
          message = options[:git] if options[:git]

          log :gemfile, message

          parts << quote(options) unless options.empty?

          in_root do
            str = []
            if comment
              comment.each_line do |comment_line|
                str << indentation
                str << "# #{comment_line}"
              end
              str << "\n"
            end
            str << indentation
            str << "gem #{parts.join(", ")}"
            append_file_with_newline "Gemfile", str.join, verbose: false
          end
        end

        # Wraps gem entries inside a group.
        #
        #   gem_group :development, :test do
        #     gem "rspec-rails"
        #   end
        def gem_group(*names, **options, &block)
          str = names.map(&:inspect)
          str << quote(options) unless options.empty?
          str = str.join(", ")
          log :gemfile, "group #{str}"

          in_root do
            append_file_with_newline "Gemfile", "\ngroup #{str} do", force: true
            with_indentation(&block)
            append_file_with_newline "Gemfile", "end", force: true
          end
        end

        def github(repo, options = {}, &block)
          str = [quote(repo)]
          str << quote(options) unless options.empty?
          str = str.join(", ")
          log :github, "github #{str}"

          in_root do
            if @indentation.zero?
              append_file_with_newline "Gemfile", "\ngithub #{str} do", force: true
            else
              append_file_with_newline "Gemfile", "#{indentation}github #{str} do", force: true
            end
            with_indentation(&block)
            append_file_with_newline "Gemfile", "#{indentation}end", force: true
          end
        end

        # Add the given source to +Gemfile+
        #
        # If block is given, gem entries in block are wrapped into the source group.
        #
        #   add_source "http://gems.github.com/"
        #
        #   add_source "http://gems.github.com/" do
        #     gem "rspec-rails"
        #   end
        def add_source(source, options = {}, &block)
          log :source, source

          in_root do
            if block
              append_file_with_newline "Gemfile", "\nsource #{quote(source)} do", force: true
              with_indentation(&block)
              append_file_with_newline "Gemfile", "end", force: true
            else
              prepend_file "Gemfile", "source #{quote(source)}\n", verbose: false
            end
          end
        end

        # Adds a line inside the Application class for <tt>config/application.rb</tt>.
        #
        # If options <tt>:env</tt> is specified, the line is appended to the corresponding
        # file in <tt>config/environments</tt>.
        #
        #   environment do
        #     "config.asset_host = 'cdn.provider.com'"
        #   end
        #
        #   environment(nil, env: "development") do
        #     "config.asset_host = 'localhost:3000'"
        #   end
        def environment(data = nil, options = {})
          sentinel = "class Application < Rails::Application\n"
          env_file_sentinel = "Rails.application.configure do\n"
          data ||= yield if block_given?

          in_root do
            if options[:env].nil?
              inject_into_file "config/application.rb", optimize_indentation(data, 4), after: sentinel, verbose: false
            else
              Array(options[:env]).each do |env|
                inject_into_file "config/environments/#{env}.rb", optimize_indentation(data, 2), after: env_file_sentinel, verbose: false
              end
            end
          end
        end
        alias_method :application, :environment

        # Run a command in git.
        #
        #   git :init
        #   git add: "this.file that.rb"
        #   git add: "onefile.rb", rm: "badfile.cxx"
        def git(commands = {})
          if commands.is_a?(Symbol)
            run "git #{commands}"
          else
            commands.each do |cmd, options|
              run "git #{cmd} #{options}"
            end
          end
        end

        # Create a new file in the <tt>vendor/</tt> directory. Code can be specified
        # in a block or a data string can be given.
        #
        #   vendor("sekrit.rb") do
        #     sekrit_salt = "#{Time.now}--#{3.years.ago}--#{rand}--"
        #     "salt = '#{sekrit_salt}'"
        #   end
        #
        #   vendor("foreign.rb", "# Foreign code is fun")
        def vendor(filename, data = nil)
          log :vendor, filename
          data ||= yield if block_given?
          create_file("vendor/#{filename}", optimize_indentation(data), verbose: false)
        end

        # Create a new file in the <tt>lib/</tt> directory. Code can be specified
        # in a block or a data string can be given.
        #
        #   lib("crypto.rb") do
        #     "crypted_special_value = '#{rand}--#{Time.now}--#{rand(1337)}--'"
        #   end
        #
        #   lib("foreign.rb", "# Foreign code is fun")
        def lib(filename, data = nil)
          log :lib, filename
          data ||= yield if block_given?
          create_file("lib/#{filename}", optimize_indentation(data), verbose: false)
        end

        # Create a new +Rakefile+ with the provided code (either in a block or a string).
        #
        #   rakefile("bootstrap.rake") do
        #     project = ask("What is the UNIX name of your project?")
        #
        #     <<-TASK
        #       namespace :#{project} do
        #         task :bootstrap do
        #           puts "I like boots!"
        #         end
        #       end
        #     TASK
        #   end
        #
        #   rakefile('seed.rake', 'puts "Planting seeds"')
        def rakefile(filename, data = nil)
          log :rakefile, filename
          data ||= yield if block_given?
          create_file("lib/tasks/#{filename}", optimize_indentation(data), verbose: false)
        end

        # Create a new initializer with the provided code (either in a block or a string).
        #
        #   initializer("globals.rb") do
        #     data = ""
        #
        #     ['MY_WORK', 'ADMINS', 'BEST_COMPANY_EVAR'].each do |const|
        #       data << "#{const} = :entp\n"
        #     end
        #
        #     data
        #   end
        #
        #   initializer("api.rb", "API_KEY = '123456'")
        def initializer(filename, data = nil)
          log :initializer, filename
          data ||= yield if block_given?
          create_file("config/initializers/#{filename}", optimize_indentation(data), verbose: false)
        end

        # Generate something using a generator from Rails or a plugin.
        # The second parameter is the argument string that is passed to
        # the generator or an Array that is joined.
        #
        #   generate(:authenticated, "user session")
        def generate(what, *args)
          log :generate, what

          options = args.extract_options!
          options[:abort_on_failure] = !options[:inline]

          rails_command "generate #{what} #{args.join(" ")}", options
        end

        # Runs the supplied rake task (invoked with 'rake ...')
        #
        #   rake("db:migrate")
        #   rake("db:migrate", env: "production")
        #   rake("gems:install", sudo: true)
        #   rake("gems:install", capture: true)
        def rake(command, options = {})
          execute_command :rake, command, options
        end

        # Runs the supplied rake task (invoked with 'rails ...')
        #
        #   rails_command("db:migrate")
        #   rails_command("db:migrate", env: "production")
        #   rails_command("gems:install", sudo: true)
        #   rails_command("gems:install", capture: true)
        def rails_command(command, options = {})
          if options[:inline]
            log :rails, command
            command, *args = Shellwords.split(command)
            in_root do
              silence_warnings do
                ::Rails::Command.invoke(command, args, **options)
              end
            end
          else
            execute_command :rails, command, options
          end
        end

        # Make an entry in Rails routing file <tt>config/routes.rb</tt>
        #
        #   route "root 'welcome#index'"
        #   route "root 'admin#index'", namespace: :admin
        def route(routing_code, namespace: nil)
          namespace = Array(namespace)
          namespace_pattern = route_namespace_pattern(namespace)
          routing_code = namespace.reverse.reduce(routing_code) do |code, name|
            "namespace :#{name} do\n#{rebase_indentation(code, 2)}end"
          end

          log :route, routing_code

          in_root do
            if namespace_match = match_file("config/routes.rb", namespace_pattern)
              base_indent, *, existing_block_indent = namespace_match.captures.compact.map(&:length)
              existing_line_pattern = /^ {,#{existing_block_indent}}\S.+\n?/
              routing_code = rebase_indentation(routing_code, base_indent + 2).gsub(existing_line_pattern, "")
              namespace_pattern = /#{Regexp.escape namespace_match.to_s}/
            end

            inject_into_file "config/routes.rb", routing_code, after: namespace_pattern, verbose: false, force: false

            if behavior == :revoke && namespace.any? && namespace_match
              empty_block_pattern = /(#{namespace_pattern})((?:\s*end\n){1,#{namespace.size}})/
              gsub_file "config/routes.rb", empty_block_pattern, verbose: false, force: true do |matched|
                beginning, ending = empty_block_pattern.match(matched).captures
                ending.sub!(/\A\s*end\n/, "") while !ending.empty? && beginning.sub!(/^ *namespace .+ do\n\s*\z/, "")
                beginning + ending
              end
            end
          end
        end

        # Reads the given file at the source root and prints it in the console.
        #
        #   readme "README"
        def readme(path)
          log File.read(find_in_source_paths(path))
        end

        private

        # Define log for backwards compatibility. If just one argument is sent,
        # invoke say, otherwise invoke say_status. Differently from say and
        # similarly to say_status, this method respects the quiet? option given.
        def log(*args) # :doc:
          if args.size == 1
            say args.first.to_s unless options.quiet?
          else
            args << ((behavior == :invoke) ? :green : :red)
            say_status(*args)
          end
        end

        # Runs the supplied command using either "rake ..." or "rails ..."
        # based on the executor parameter provided.
        def execute_command(executor, command, options = {}) # :doc:
          log executor, command
          sudo = (options[:sudo] && !Gem.win_platform?) ? "sudo " : ""
          config = {
            env: {"RAILS_ENV" => (options[:env] || ENV["RAILS_ENV"] || "development")},
            verbose: false,
            capture: options[:capture],
            abort_on_failure: options[:abort_on_failure]
          }

          in_root { run("#{sudo}#{Shellwords.escape Gem.ruby} bin/#{executor} #{command}", config) }
        end

        # Always returns value in double quotes.
        def quote(value) # :doc:
          if value.respond_to? :each_pair
            return value.map do |k, v|
              "#{k}: #{quote(v)}"
            end.join(", ")
          end
          return value.inspect unless value.is_a? String

          "\"#{value.tr("'", '"')}\""
        end

        # Returns optimized string with indentation
        def optimize_indentation(value, amount = 0) # :doc:
          return "#{value}\n" unless value.is_a?(String)
          "#{value.strip_heredoc.indent(amount).chomp}\n"
        end
        alias_method :rebase_indentation, :optimize_indentation

        # Indent the +Gemfile+ to the depth of @indentation
        def indentation # :doc:
          "  " * @indentation
        end

        # Manage +Gemfile+ indentation for a DSL action block
        def with_indentation(&block) # :doc:
          @indentation += 1
          instance_eval(&block)
        ensure
          @indentation -= 1
        end

        # Append string to a file with a newline if necessary
        def append_file_with_newline(path, str, options = {})
          gsub_file path, /\n?\z/, options do |match|
            match.end_with?("\n") ? "" : "\n#{str}\n"
          end
        end

        def match_file(path, pattern)
          File.read(path).match(pattern) if File.exist?(path)
        end

        def route_namespace_pattern(namespace)
          namespace.each_with_index.reverse_each.reduce(nil) do |pattern, (name, i)|
            cummulative_margin = "\\#{i + 1}[ ]{2}"
            blank_or_indented_line = "^[ ]*\n|^#{cummulative_margin}.*\n"
            "(?:(?:#{blank_or_indented_line})*?^(#{cummulative_margin})namespace :#{name} do\n#{pattern})?"
          end.then do |pattern|
            /^( *).+\.routes\.draw do *\n#{pattern}/
          end
        end
      end
    end


    include Thor::Actions
    include Rails::Actions

    # Custom methods defined on AppGenerator
    # https://github.com/rails/rails/blob/38275763257221e381cd4e37958ce1413fd0433c/railties/lib/rails/generators/rails/app/app_generator.rb#L558
    def file(*args, &block)
      create_file(*args, &block)
    end
  end
end
