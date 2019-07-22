# Be sure to restart your server when you modify this file.

HyperCheese::Application.config.session_store :cookie_store, key: '_hyper_cheese_session', expire_after: 60 * 60 * 24 * 365 * 10, secure: Rails.env.production?

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rails generate session_migration")
# HyperCheese::Application.config.session_store :active_record_store
