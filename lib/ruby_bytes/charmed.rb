# frozen_string_literal: true

require "lipgloss"
require "gum"

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

      buffer = set_color(message, *Array(color))

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
      return if quiet? || log_status == false

      draw_box!

      color_code = log_status.is_a?(Symbol) ? FG_COLORS.fetch(log_status) : FG_COLORS.fetch(STATUS_COLORS.fetch(status, STATUS_COLORS[:info]))

      status_style = Lipgloss::Style.new.bold(true).foreground(color_code).inline(true)
      buffer = "#{status_style.render(status.to_s.upcase)}\t#{message}"

      stdout.puts(buffer)
      stdout.flush
    end

    # Print an error message to $stderr.
    # Thor default: same as +say+ but writes to $stderr.
    def say_error(message = "", color = :red, force_new_line = (message.to_s !~ /( |\t)\Z/))
      return if quiet?

      draw_box!

      # Print error in a box
      error_style = Lipgloss::Style.new
        .padding(1, 1)
        .align(:center)
        .background(FG_COLORS.fetch(color))
      buffer = error_style.render(message)
      stderr.puts(buffer)
      stderr.flush
    end

    # Print an unformatted error statement to $stderr (legacy Thor method).
    # Thor default: $stderr.puts statement.
    def error(statement)
      say_error(statement)
    end

    # Print an array of strings in evenly-spaced columns.
    # Thor default: calculates column widths and pads with spaces.
    def print_in_columns(array)
      return if quiet?

      draw_box!

      return if array.empty?

      if array.size <= 4
        stdout.puts Lipgloss::List.new.items(array.map(&:to_s)).render
        stdout.flush
        return
      end

      col_width = array.map { |e| e.to_s.size }.max + 2
      cols = [terminal_width / col_width, array.size].min.clamp(4..)

      # Shrink columns so the last row has at least cols-2 items
      while cols > 4
        remainder = array.size % cols
        break if remainder.zero? || remainder >= cols - 2
        cols -= 1
      end

      even_style = Lipgloss::Style.new.width(col_width).inline(true).align(:center).background("254").foreground("0")
      odd_style = Lipgloss::Style.new.width(col_width).inline(true).align(:center).background("234")

      rows = array.each_slice(cols).map.with_index do |row, ri|
        Lipgloss.join_horizontal(:top, *row.map.with_index { |item, ci| ((ri + ci).even? ? even_style : odd_style).render(item.to_s) })
      end

      buffer = Lipgloss.join_vertical(:left, *rows)

      stdout.puts(buffer)
      stdout.flush
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

      style = Lipgloss::Style.new.background("234")
      buffer = style.render(message)
      super(buffer)
    end

    # ── Input ─────────────────────────────────────────────────────────────

    # Prompt the user for a single line of text.
    # Thor default: readline with optional :default, :limited_to, :echo, :path.
    def ask(statement, *args)
      draw_box!

      options = args.last.is_a?(Hash) ? args.pop : {}
      # color = args.first

      if options[:limited_to]
        Gum.choose(options[:limited_to], header: statement, selected: options[:default])
      else
        Gum.input(value: options[:default], prompt: "> ", header: statement)
      end.then { |v| handle_gum_result(v) }
    end

    # Ask a yes/no question, return true when the user answers "y" or "yes".
    # Thor default: regex match on the answer string.
    def yes?(statement, color = nil)
      draw_box!

      handle_gum_result(
        Gum.choose(%w[Yes No], header: statement, selected: "Yes")
      ).then { |res| res == "Yes" }
    end

    # Ask a yes/no question, return true when the user answers "n" or "no".
    # Thor default: inverse of +yes?+.
    def no?(statement, color = nil)
      draw_box!

      handle_gum_result(
        Gum.choose(%w[Yes No], header: statement, selected: "Yes")
      ).then { |res| res == "No" }
    end

    # ── Formatting / Utility ──────────────────────────────────────────────

    # Apply color and style to a string.
    # Thor default: wraps string in ANSI escape codes.
    def set_color(string, *colors)
      style = Lipgloss::Style.new.inline(true)
      colors.each do |c|
        case c
        when :bold then style = style.bold(true)
        when :on_black, :on_red, :on_green, :on_yellow, :on_blue, :on_magenta, :on_cyan, :on_white
          style = style.background(BG_COLORS.fetch(c.to_s.sub("on_", "").to_sym))
        when Symbol then style = style.foreground(FG_COLORS.fetch(c))
        end
      end

      style.render(string.to_s)
    end

    # Return the width (in columns) of the current terminal.
    # Thor default: detects via IO/stty (class method on Thor::Shell::Terminal).
    def terminal_width
      Thor::Shell::Terminal.terminal_width
    end

    private

    def box_buffer
      @box_buffer ||= []
    end

    def append_to_current_box(line)
      box_buffer << line
    end

    def draw_box!
      return stdout.puts if box_buffer.empty?

      # Single line is printed as is
      buffer =
        if box_buffer.size == 1
          box_buffer.first
        else
          Lipgloss::Style.new
            .border(:normal)
            .padding(1, 2)
            .align(:center)
            .render(box_buffer.join("\n"))
        end

      stdout.puts(buffer)
      stdout.flush

      box_buffer.clear
    end

    def handle_gum_result(res)
      # nil means user cancelled
      # https://github.com/marcoroth/gum-ruby/blob/faf9e2ccefa6457708a4eb31c992e0ccf585a998/lib/gum/command.rb#L46
      Kernel.exit(130) if res.nil?
      res
    end
  end
end
