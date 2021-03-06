class Reservation < ActiveRecord::Base
  belongs_to :location
  belongs_to :member
  validate :dates_are_available, :dates_are_not_in_past, :no_available_date_set
  validate :dates_are_available, on: :create
  scope :upcoming, ->(member_id){ where("start_date > ?", Date.today).where(member_id: member_id) if member_id.present? }
  scope :not_cancelled, ->{ where(id_for_refund: nil) }

  scope :reservations_for_host, ->(host) { joins(:location).merge(Location.where(member_id: host.id)) if host.present? }

  def dates_are_available
    start_date_overlap = location.reservations.where(start_date:
    start_date..end_date - 1.day)
    end_date_overlap = location.reservations.where(end_date:
    start_date..end_date - 1.day)
    if start_date_overlap.exists? || end_date_overlap.exists?
      errors[:base] << "Some of the dates of your reservation are not
      available. Please try different dates."
    end
  end

  def dates_are_not_in_past
    if start_date < Date.today || end_date < Date.today
      errors[:base] << "The reservation should not be in the past. Please try different dates."
    end
  end

  def no_available_date_set
    reservation_array =  (start_date..end_date).to_a
    available_dates = AvailableDate.where(location_id: location.id).where(available_date: reservation_array)
    if available_dates.count == 0
      errors[:base] << "Host has not set an available date for this location"
    end
  end

  def update_after_refund(id_for_refund)
    update(id_for_refund: id_for_refund)
    reservation_array = (start_date..end_date).to_a
    available_dates = AvailableDate.where(location_id:
    location.id).where(available_date: reservation_array)
    available_dates.update_all(reserved: false)
  end
end
