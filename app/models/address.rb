class Address < ActiveRecord::Base
  belongs_to :location
  geocoded_by :full_street_address

  after_validation :geocode, if: ->(obj){ obj.street.present? and obj.address_changed? }

  validates :postal_code, numericality: true

  def country_name(country_code)
    country = ISO3166::Country[country_code]
    country.translations[I18n.locale.to_s] || country.name
  end
   
  def full_street_address
   [street, city, postal_code, region, country].compact.join(", ")
  end

  def address_changed?
    street_changed? || city_changed? || region_changed? || country_changed?
  end

  def self.city_names
    Address.distinct.pluck(:city).sort!
  end

  def self.region_names
  Address.distinct.pluck(:region).sort!
  end
end
