# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_crawler_session',
  :secret      => 'e4f9b5ab03ba56a787ad0c991a91f71cd89f75a49811f7c182675d49a2a1073219385fdb88c03b25abb30c273a6364739ac1c7299a919834a1ab885d3d82ef16'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
