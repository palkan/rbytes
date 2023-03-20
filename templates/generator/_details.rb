name = nil

loop do
  name = ask("What is the name of your template?") || ""
  if name.empty?
    say "Hm, empty name doesn't work. Let's try again"
  else
    break
  end
end

root_dir = ask("Where do you want to store the code? (Default: #{File.join(Dir.pwd, name)})")

if root_dir.nil? || root_dir.empty?
  root_dir = File.join(Dir.pwd, name)
end

human_name = name.split(/[-_]/).map(&:capitalize).join(" ")

needs_rails = yes? "Is this a Rails application template?"
