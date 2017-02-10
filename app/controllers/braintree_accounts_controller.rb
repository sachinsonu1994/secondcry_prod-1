class BraintreeAccountsController < ApplicationController
  require 'net/http'

  LIST_OF_STATES = [
      ['Alabama', 'AL'],
      ['Alaska', 'AK'],
      ['Arizona', 'AZ'],
      ['Arkansas', 'AR'],
      ['California', 'CA'],
      ['Colorado', 'CO'],
      ['Connecticut', 'CT'],
      ['Delaware', 'DE'],
      ['District of Columbia', 'DC'],
      ['Florida', 'FL'],
      ['Georgia', 'GA'],
      ['Hawaii', 'HI'],
      ['Idaho', 'ID'],
      ['Illinois', 'IL'],
      ['Indiana', 'IN'],
      ['Iowa', 'IA'],
      ['Kansas', 'KS'],
      ['Kentucky', 'KY'],
      ['Louisiana', 'LA'],
      ['Maine', 'ME'],
      ['Maryland', 'MD'],
      ['Massachusetts', 'MA'],
      ['Michigan', 'MI'],
      ['Minnesota', 'MN'],
      ['Mississippi', 'MS'],
      ['Missouri', 'MO'],
      ['Montana', 'MT'],
      ['Nebraska', 'NE'],
      ['Nevada', 'NV'],
      ['New Hampshire', 'NH'],
      ['New Jersey', 'NJ'],
      ['New Mexico', 'NM'],
      ['New York', 'NY'],
      ['North Carolina', 'NC'],
      ['North Dakota', 'ND'],
      ['Ohio', 'OH'],
      ['Oklahoma', 'OK'],
      ['Oregon', 'OR'],
      ['Pennsylvania', 'PA'],
      ['West Virginia', 'WV'],
      ['Wisconsin', 'WI'],
      ['Wyoming', 'WY']
    ]

  before_filter do |controller|
    controller.ensure_logged_in t("layouts.notifications.you_must_log_in_to_change_payment_settings")
  end

  # Commonly used paths
  before_filter do |controller|
    @create_path = create_braintree_settings_payment_path(@current_user)
    @show_path = show_braintree_settings_payment_path(@current_user)
    @new_path = new_braintree_settings_payment_path(@current_user)
    @update_path = update_braintree_settings_payment_path(@current_user)
  end

  # New/create
  before_filter :ensure_user_does_not_have_account, :only => [:new,:create]
  before_filter :ensure_user_does_not_have_account_for_another_community

  def check_ifsc_code
    response_hash = Hash.new
    if !params[:ifsc_code].blank?
      uri = URI("https://ifsc.razorpay.com/#{params[:ifsc_code]}")
      response = Net::HTTP.get(uri)
      if response.include?('Not Found')
        response_hash[:status] = "failure"
      else
        api_response = JSON.parse(response)
        response_hash[:bank_name] = api_response["BANK"]
        response_hash[:branch] = api_response["BRANCH"]
        response_hash[:status] = "success"
      end
    end
    render :json => response_hash.to_json, :callback => params[:callback]
  end
  
  def new
    redirect_to action: :show and return if @current_user.braintree_account
    @braintree_account = create_new_account_object
    render locals: { form_action: @create_path }
  end

  def show
    redirect_to action: :new and return unless @current_user.braintree_account
    @braintree_account = BraintreeAccount.find_by_person_id(@current_user.id)
    render locals: { form_action: @update_path }
  end

  def create
    braintree_params = params.require(:braintree_account).permit(
      :person_id,
      :first_name,
      :ifsc_number,
      :account_number,
      :bank_name_and_branch   
    )

    model_attributes = braintree_params
      .merge(person: @current_user)
      .merge(community_id: @current_community.id)
      
    @braintree_account = BraintreeAccount.new(model_attributes)
    if @braintree_account.valid?
      @braintree_account.save
      redirect_to @show_path
    else
      flash[:error] = @braintree_account.errors.full_messages
      render :new, locals: { form_action: @create_path } and return
    end
  end
  
  def update
    braintree_account = BraintreeAccount.find_by_person_id(@current_user.id)
    braintree_account.first_name = params[:braintree_account][:first_name]
    braintree_account.account_number = params[:braintree_account][:account_number]
    braintree_account.ifsc_number = params[:braintree_account][:ifsc_number]
    braintree_account.bank_name_and_branch = params[:braintree_account][:bank_name_and_branch]
    braintree_account.save   
    if braintree_account.save   
      redirect_to @show_path
    else
      render :new, locals: { form_action: @create_path } and return
    end
  end

  private

  # Before filter
  def ensure_user_does_not_have_account
    braintree_account = BraintreeAccount.find_by_person_id(@current_user.id)

    unless braintree_account.blank?
      #flash[:error] = "Cannot create a new Braintree account. You already have one"
      redirect_to @show_path
    end
  end

  # Before filter
  # Support for multiple Braintree account in multipe communities
  # is not implemented. Show error.
  def ensure_user_does_not_have_account_for_another_community
    @braintree_account = BraintreeAccount.find_by_person_id(@current_user.id)

    if @braintree_account
      # Braintree account exists
     if @braintree_account.community_id.present? && @braintree_account.community_id != @current_community.id
        # ...but is associated to different community
       account_community = Community.find(@braintree_account.community_id)
       flash[:error] = "You have payment account for community #{account_community.name(I18n.locale)}. Unfortunately, you cannot have payment accounts for multiple communities. You are unable to receive money from transactions in community #{@current_community.name(I18n.locale)}. Please contact administrators."
       error_msg = "User #{@current_user.id} tried to create a Braintree payment account for community #{@current_community.name(I18n.locale)} even though she has existing account for #{account_community.name(I18n.locale)}"
       BTLog.error(error_msg)
       ApplicationHelper.send_error_notification(error_msg, "BraintreePaymentAccountError")
       redirect_to person_settings_path(@current_user)
     end
    end
  end

  # Give `braintree_account` and `new_status` candidate. Update the status, unless the status is already
  # active
  #
  # Background: If the webhook has already update the status to "active", we don't want to change it back
  # to pending. This may happen in sandbox environment, where the webhook is triggered very fast
  def update_status!(braintree_account, new_status)
    braintree_account.reload
    braintree_account.status = new_status if braintree_account.status != "active"
    braintree_account.save!
  end

  def create_new_account_object
    person = @current_user
    person_details = {
      first_name: person.given_name,
      last_name: person.family_name,
      email: person.confirmed_notification_email_to, # Our best guess for "primary" email
      phone: person.phone_number
    }

    BraintreeAccount.new(person_details)
  end
end