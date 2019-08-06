class PurchasesController < ApplicationController

  def show
    @purchase = Purchase.find(params[:id])
    if !@purchase.merchandise_id.nil? #If this is a donation do not look for merchandise
      loot      = Merchandise.find(@purchase.merchandise_id)
      @itemname = loot.name
      id        = loot.user_id
      @user     = User.find(id)
    end
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @purchase }
    end
  end

  def new
    if params[:pricesold].present? # Donation being made
      @purchase = Purchase.new
    elsif params[:merchandise_id].present? #Purchase being made
      @merchandise = Merchandise.find(params[:merchandise_id])
      @purchase = @merchandise.purchases.new
    end
    if user_signed_in? && current_user.stripe_customer_token.present?
      @card     = @purchase.retrieve_customer_card(current_user)
      @last4    = @card.last4
      @expmonth = @card.exp_month
      @expyear  = @card.exp_year
    end
  end

  def create
    @purchase                      = Purchase.new(purchase_params)
    @purchase_mailer_hash          = { purchase: @purchase }
    @merchandise                   = Merchandise.find(@purchase.merchandise_id)
    @seller                        = User.find(@merchandise.user_id)
    @purchase_mailer_hash[:seller] = @seller

    case @merchandise.buttontype
    when 'Donate'
      assign_user_id
      case @purchase.save_with_payment
      when true
        PurchaseMailer.with(@purchase_mailer_hash).donation_saved.deliver_later
        PurchaseMailer.with(@purchase_mailer_hash).donation_received.deliver_later
        flash[:notice] = 'You successfully donated $' + @merchandise.price.to_s + ' . Thank you for being a donor of ' + @seller.name
        redirect_to user_profile_path(@seller.permalink)
      when false
        redirect_back fallback_location: request.referrer, notice: 'Your order did not go through. Try again.'
      end
    when 'Buy'
      assign_user_id
      case @purchase.save_with_payment
      when true
        @purchase_mailer_hash[:merchandise] = @merchandise
        PurchaseMailer.with(@purchase_mailer_hash).purchase_saved.deliver_later
        PurchaseMailer.with(@purchase_mailer_hash).purchase_received.deliver_later
        filename_and_data = @merchandise.get_filename_and_data
        filename = filename_and_data[0]
        data = filename_and_data[1]
        send_data_to_buyer data, filename and return
        redirect_to user_profile_path(@seller.permalink)
      when false
        redirect_back fallback_location: request.referrer, notice: 'Your order did not go through. Try again.'
      end
    end
  end
  # GET /purchases/receipt
  def receipt
  end

  private

  def assign_user_id
    case user_signed_in?
    when true
      @purchase.user_id = current_user.id
      @purchase_mailer_hash[:user] = User.find(@purchase.user_id)
    when false
    end
  end

  def send_data_to_buyer data, filename
      send_data data.read , filename: filename, disposition: 'attachment'
  end

  def purchase_params
    params.require(:purchase).permit(:stripe_customer_token, :bookfiletype,
                                     :groupcut, :shipaddress, :book_id,
                                     :stripe_card_token,:pricesold, :user_id,
                                     :author_id, :merchandise_id, :group_id,
                                     :email)
  end

end
