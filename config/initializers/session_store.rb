# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_online_bookings_session',
  :secret      => '77cd459f244d62599d60fa0a990ba8bb2af0357b1d3ff956ca4e3d948d1621f873b7781341a96e2924ad119d06b9145285a0003d112b8e57f0e68b1af9193930'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
