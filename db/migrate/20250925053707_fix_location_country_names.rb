require 'csv'

class FixLocationCountryNames < ActiveRecord::Migration[7.2]
  def up
    # Load country code mapping
    country_codes = load_country_codes

    # Find locations with three-character geoids that match country codes
    locations_to_update = Location.where("geoid REGEXP '^[A-Z]{3}$'")

    puts "Found #{locations_to_update.count} locations with three-character geoids"

    updated_count = 0
    locations_to_update.find_each do |location|
      if country_codes[location.geoid]
        old_name = location.name
        new_name = country_codes[location.geoid]

        if old_name != new_name
          location.update!(name: new_name)
          puts "Updated #{location.geoid}: '#{old_name}' -> '#{new_name}'"
          updated_count += 1
        end
      end
    end

    puts "Updated #{updated_count} location names"
  end

  def down
    # This migration is not easily reversible since we don't store the original names
    # If you need to reverse this, you would need to manually restore the original names
    puts "This migration cannot be automatically reversed"
  end

  private

  def load_country_codes
    csv_path = Rails.root + "db/geo/wikipedia-iso-country-codes.csv"
    country_codes = {}

    CSV.foreach csv_path, headers: true do |row|
      alpha3 = row['Alpha-3 code']
      country_name = row['English short name lower case']
      country_codes[alpha3] = country_name if alpha3 && country_name
    end

    country_codes
  end
end
