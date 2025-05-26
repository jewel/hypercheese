path = "#{Rails.root}/.secret_key_base"

if !File.exist?(path)
  raise "Missing secret key.  Create it by running 'rake secret > #{path}'"
end

HyperCheese::Application.config.secret_key_base = File.read(path).chomp
