RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  Dir[File.dirname(__FILE__) + "/support/**/*.rb"].each {|f| require f}
end
