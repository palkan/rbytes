# frozen_string_literal: true

# ─── Charmed Thor demo ─────────────────────────────────────────────────
# Run with:
#   bundle exec bin/rbytes install ./examples/charmed.rb
#
# This template exercises every Thor shell method that the Charmed module
# overrides, so you can see the before/after difference.
# ───────────────────────────────────────────────────────────────────────

# ── say ───────────────────────────────────────────────────────────────
say "👋 Welcome to the Charmed Thor demo!\n"
say "This line is plain."
say "This line is green.", :green
say "This line is yellow on red.", [:yellow, :on_red]
say "This line is cyan.", :cyan
say "This line is bold red.", [:red, :bold]

# ── say_status ────────────────────────────────────────────────────────
say_status :info, "Charmed module loaded"
say_status :create, "config/charmed.yml", :green
say_status :skip, "already exists", :yellow
say_status :error, "something went wrong", :red

# ── say_error / error ────────────────────────────────────────────────
say_error "This is a warning printed to stderr."
say ""

# ── print_table ──────────────────────────────────────────────────────
say "Here is a table of Charm Ruby gems:"
print_table [
  ["Gem", "Purpose"],
  ["lipgloss", "Styling & layout"],
  ["huh", "Terminal forms"],
  ["gum", "Glamorous shell scripts"],
  ["glamour", "Markdown rendering"],
  ["bubbletea", "TUI framework"],
  ["bubbles", "TUI components"]
]
say ""

# ── print_in_columns ─────────────────────────────────────────────────
say "Available components:", :blue
print_in_columns %w[Spinner Progress Timer TextInput TextArea Viewport List Table FilePicker]
say ""

say "Available log levels:", :blue
print_in_columns %w[Info Warn Debug Error]
say ""

# ── print_wrapped ────────────────────────────────────────────────────
say "A wrapped paragraph:", :blue
print_wrapped "Charmed integrates the Charm Ruby ecosystem into Thor so that every " \
              "template you write gets beautiful, accessible terminal UI for free. " \
              "No more plain-text prompts — get styled output, interactive forms, " \
              "and rich tables without changing your template code."
say ""

# ── ask ──────────────────────────────────────────────────────────────
name = ask("What is your name?", default: "Martian")
say "Hello, #{name}! 🚀"

language = ask("Pick a language:", limited_to: %w[Ruby Go TypeScript Rust], default: "Go")
say "Great choice: #{language}"

# ── yes? / no? ───────────────────────────────────────────────────────
if yes?("Do you like terminal UIs?")
  say "🎉 We knew it!"
else
  if no?("Are you a GUI lover?")
    say "🎉 We knew it!"
  else
    say "Okay, no comments."
  end
  say ""
end

return

# ── file_collision (create_file triggers it when file exists) ────────
file "charmed_demo.txt", "Hello from the Charmed demo!\n"
file "charmed_demo.txt", "This triggers a file collision prompt.\n"

# ── Cleanup ──────────────────────────────────────────────────────────
remove_file "charmed_demo.txt"

say "✨ Demo complete!"
