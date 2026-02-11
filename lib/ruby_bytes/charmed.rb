# frozen_string_literal: true

require "gum"
require "lipgloss"

class Rbytes
  module Charmed
    # See https://gist.github.com/JBlond/2fea43a3049b38287e5e9cefc87b2124?permalink_comment_id=3892823#gistcomment-3892823
    FG_COLORS = {
      black: "8",
      red: "9",
      green: "10",
      yellow: "11",
      blue: "12",
      magenta: "13",
      cyan: "14",
      white: "15",
      grey: "243"
    }.freeze

    BG_COLORS = {
      black: "16",
      red: "124",
      green: "28",
      yellow: "214",
      blue: "25",
      magenta: "95",
      cyan: "45",
      white: "231",
      grey: "252"
    }.freeze

    # Print a message to the user.
    # say accumulates messages to print them in a box in case more than a single message is provided.
    # the empty string is used to flush the output; any other command flushes the output, too.
    def say(message = "", color = nil, force_new_line = (message.to_s !~ /( |\t)\Z/))
      return if quiet?

      return draw_box! if message == ""

      opts = {}
      Array(color).each do |c|
        case c
        when :bold then opts[:bold] = true
        when :on_black, :on_red, :on_green, :on_yellow, :on_blue, :on_magenta, :on_cyan, :on_white
          opts[:background] = BG_COLORS.fetch(c.to_s.sub("on_", "").to_sym)
        when Symbol then opts[:foreground] = FG_COLORS.fetch(c)
        end
      end

      buffer = Gum.style(message.to_s, **opts)
      # TODO: how to handle force_new_line ?
      # buffer << "\n" if force_new_line && !message.to_s.end_with?("\n")

      append_to_current_box(buffer)
    end

    STATUS_COLORS = {
      debug: :grey,
      info: :blue,
      warn: :yellow,
      error: :red,
      fatal: :red
    }.freeze

    # Print a status badge followed by a message (e.g. "  create  config/routes.rb").
    # Thor default: right-aligns the status word, colors it, appends the message.
    def say_status(status, message, log_status = true)
      return if quiet?

      draw_box!

      color_code = log_status.is_a?(Symbol) ? FG_COLORS.fetch(log_status) : FG_COLORS.fetch(STATUS_COLORS.fetch(status, STATUS_COLORS[:info]))

      buffer = Gum.format(%({{ Bold (Color "#{color_code}" "#{status.to_s.upcase}") }}\t#{message}), type: :template)

      stdout.puts(buffer)
      stdout.flush
    end

    # Print an error message to $stderr.
    # Thor default: same as +say+ but writes to $stderr.
    def say_error(message = "", color = :red, force_new_line = (message.to_s !~ /( |\t)\Z/))
      return if quiet?

      draw_box!

      # Print error in a box
      buffer = Gum.style(message, border: :hidden, padding: "1 1", align: "center", background: FG_COLORS.fetch(color))
      stderr.puts(buffer)
      stderr.flush
    end

    # Print an unformatted error statement to $stderr (legacy Thor method).
    # Thor default: $stderr.puts statement.
    def error(statement)
      return if quiet?

      draw_box!

      super
    end

    # Print an array of strings in evenly-spaced columns.
    # Thor default: calculates column widths and pads with spaces.
    def print_in_columns(array)
      return if quiet?

      draw_box!

      super
    end

    # Print a 2-D array as an aligned table.
    # Thor default: ASCII table with optional indent, colwidth, borders.
    #
    # ==== Options
    #   indent<Integer>   – indent the first column
    #   colwidth<Integer> – force the first column width
    #   borders<Boolean>  – draw borders
    def print_table(data, options = {})
      return if quiet?

      draw_box!

      data = data.dup
      headers = data.shift

      header_style = Lipgloss::Style.new.bold(true).foreground("12")
      even_style = Lipgloss::Style.new.background("254").foreground("0")
      odd_style = Lipgloss::Style.new.background("234")

      table = Lipgloss::Table.new
        .headers(headers)
        .rows(data)
        .style_func(rows: data.size, columns: headers.size) do |row, column|
          if row == Lipgloss::Table::HEADER_ROW
            header_style
          elsif row.even?
            even_style
          else
            odd_style
          end
        end

      buffer = table.render
      # buffer = Gum.table(data, columns: headers, print: true)

      stdout.puts(buffer)
      stdout.flush
    end

    # Print a long string, word-wrapped to the terminal width.
    # Thor default: wraps text at terminal_width minus indent.
    #
    # ==== Options
    #   indent<Integer> – left-indent each line
    def print_wrapped(message, options = {})
      return if quiet?

      draw_box!

      super
    end

    # ── Input ─────────────────────────────────────────────────────────────

    # Prompt the user for a single line of text.
    # Thor default: readline with optional :default, :limited_to, :echo, :path.
    def ask(statement, *args)
      draw_box!

      super
    end

    # Ask a yes/no question, return true when the user answers "y" or "yes".
    # Thor default: regex match on the answer string.
    def yes?(statement, color = nil)
      draw_box!

      super
    end

    # Ask a yes/no question, return true when the user answers "n" or "no".
    # Thor default: inverse of +yes?+.
    def no?(statement, color = nil)
      draw_box!

      super
    end

    # ── Formatting / Utility ──────────────────────────────────────────────

    # Apply color and style to a string.
    # Thor default: wraps string in ANSI escape codes.
    def set_color(string, *colors)
      draw_box!

      super
    end

    # Handle a file-overwrite collision.
    # Thor default: interactive Y/n/a/q/d/h/m loop via +ask+.
    def file_collision(destination)
      draw_box!

      super
    end

    # Return the width (in columns) of the current terminal.
    # Thor default: detects via IO/stty.
    # Charmed:      use Lipgloss.width (Go-backed precise detection) when
    #               available, otherwise fall back to Thor's implementation.
    def terminal_width
      super
    end

    # ── Internal (Rails::Actions) ─────────────────────────────────────────

    # Log a generator action. Called by every Thor::Actions helper
    # (create_file, inject_into_file, gem, route, …).
    # Single-arg form calls +say+; two-arg form calls +say_status+.
    # Thor default: delegates to say / say_status.
    # Charmed:      optionally use Gum::Log for structured, level-aware
    #               output; otherwise piggy-backs on the charmed +say+ /
    #               +say_status+ overrides above.
    def log(*args)
      return if quiet?

      draw_box!

      super
    end

    private

    def box_buffer
      @box_buffer ||= []
    end

    def append_to_current_box(line)
      box_buffer << line
    end

    def draw_box!
      return if box_buffer.empty?

      # Single line is printed as is
      buffer =
        if box_buffer.size == 1
          box_buffer.first
        else
          Gum.style(box_buffer.join("\n"), border: :normal, padding: "1 2", align: "center")
        end

      stdout.puts(buffer)
      stdout.flush

      box_buffer.clear
    end
  end
end
