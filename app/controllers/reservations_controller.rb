class ReservationsController < ApplicationController

  def index
    @member = current_member
    if is_host(@member)
      @reservations = Reservation.reservations_for_host(@member)
    else
      @reservations = Reservation.not_cancelled.upcoming(@member.id)
    end
  end

  def show
    @member = current_member
    @reservation = Reservation.find(params[:id])
    @location = Location.find(@reservation.location_id)
    host = Member.find(@location.member_id)
    @host_profile = host.profile
    @address = @location.address
  end

  def new
    @reservation = Reservation.new(reservation_params)
    @location = @reservation.location
  end

  def create
    @reservation = Reservation.new(reservation_params)
    @location = @reservation.location
    @token = params[:stripe_token]
    if @reservation.valid?
      begin
        @customer_charge = charge_customer(@token, @location, @reservation)
        @reservation.id_for_credit_card_charge = @customer_charge.id
      rescue Stripe::CardError => e
        body = e.json_body
        message = body[:error][:message]
        flash[:alert] = message
      end
    else
      flash[:alert] = "Some of the dates of your reservation are not available.
      Please try different dates."
    end
    respond_to do |format|
      if !@customer_charge.nil?
        @reservation.save
        reservation_array = (@reservation.start_date..@reservation.end_date -
        1.day).to_a
        ReservationConfirmationMailer.send_customer_reservation_confirmation(@reservation).deliver_now
        ReservationConfirmationMailer.send_host_reservation_confirmation(@reservation).deliver_now
        AvailableDate.where(location_id: @location.id).where(available_date:
        reservation_array).update_all(reserved: true)
        format.html { redirect_to reservation_confirmation_path(@reservation),
        notice: "Reservation successfully created." }

        day_before = @reservation.start_date - 1.day
        ReservationReminderJob.set(wait_until: day_before.noon).perform_later(@reservation)
      else
        if Rails.env == "test"
          sleep 2
        end
        format.html {redirect_to new_reservation_path(
        reservation: {start_date: @reservation.start_date,
        end_date: @reservation.end_date, location_id: @location.id})}
      end
    end
  end

  def confirmation
    @reservation = Reservation.find(params[:reservation_id])
  end


  def cancel
    @reservation = Reservation.find(params[:id])
    begin
      refund = refund_customer(@reservation)
      @id_for_refund = refund[:refunds][:data][0][:id]
    rescue Stripe::StripeError => e
      body = e.json_body
      message = body[:error][:message]
      flash[:alert] = message
    end
    if !@id_for_refund.nil?
      @reservation.update_after_refund(@id_for_refund)
      redirect_to reservations_path, notice: "Your reservation was successfully
      cancelled."
      ReservationCancellationJob.perform_later(@reservation)
    else
      redirect_to reservations_path
    end
  end

  private

  def reservation_params
    params.required(:reservation).permit(:start_date, :end_date, :member_id, :location_id)
  end

  def charge_customer(source, location, reservation)
    CreditCardService.new({
    source: source,
    location: location,
    reservation: reservation
    }).charge_customer
  end


  def refund_customer(reservation)
    CreditCardService.new({ reservation: reservation }).refund_customer
  end

  def is_host(member)
    profile = Profile.find(member.id)
    profile.is_host?
  end
end
