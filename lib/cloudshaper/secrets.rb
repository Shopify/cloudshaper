require 'json'
require 'open3'

SECRETS ||= {}

secrets_files = (ENV['SECRETS_FILES'] || '/usr/local/cloudshaper/secrets.ejson,config/secrets.ejson').split(',')
secrets_files.each do |secrets_file|
  if File.exist?(secrets_file)
    if secrets_file.end_with?('.ejson')
      secrets = `ejson decrypt #{secrets_file}`
    elsif secrets_file.end_with('.json')
      secrets = File.read(secrets_file)
    else
      fail "I don't understand how to get secrets from #{secrets_file}"
    end
    SECRETS.merge!(JSON.parse(secrets))
  end
end
