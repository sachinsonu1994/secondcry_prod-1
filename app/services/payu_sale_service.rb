class PayuSaleService
  def initialize(payment, payment_params)
    subunit_to_unit = Money::Currency.new(payment.currency).subunit_to_unit

    @payment = payment
    @community = payment.community
    @payer = payment.payer
    @recipient = payment.recipient
    @amount = payment.sum_cents.to_f / subunit_to_unit
    @service_fee = payment.total_commission.cent.to_f / subunit_to_unit
    @params = payment_params || {}
  end

  def pay(submit_for_settlement)
    if result.success?
      result = call_payu_api(submit_for_settlement)
      change_payment_status_to_paid!
    end

    log_result(result)

    result
  end

  private

  def call_payu_api(submit_for_settlement)
    with_exception_logging do
      BTLog.warn("Sending sale transaction from #{@payer.id} to #{@recipient.id}. Amount: #{@amount}, fee: #{@service_fee}")

      PayuApi.transaction_sale(@community,
        type:                    "sale",
        amount:                  @amount.to_s,
        merchant_account_id:     @recipient.id,

        credit_card: {
          number:                @params[:credit_card_number],
          expiration_month:      @params[:credit_card_expiration_month],
          expiration_year:       @params[:credit_card_expiration_year],
          cvv:                   @params[:cvv],
          cardholder_name:       @params[:cardholder_name],
        },

        options: {
          submit_for_settlement: submit_for_settlement,
          hold_in_in_escrow:     @community.payment_gateway.hold_in_escrow
        },
        service_fee_amount:     @service_fee.to_s
      )
    end
  end

  def save_transaction_id(result)
    @payment.update_attributes(payu_transaction_id: result.transaction.id)
  end

  def change_payment_status_to_paid!
    @payment.paid!
  end

  def log_result(result)
    if result.success?
      transaction_id = result.transaction.id
      BTLog.warn("Successful sale transaction #{transaction_id} from #{@payer.id} to #{@recipient.id}. Amount: #{@amount}, fee: #{@service_fee}")
    else
      BTLog.error("Unsuccessful sale transaction from #{@payer.id} to #{@recipient.id}. Amount: #{@amount}, fee: #{@service_fee}: #{result.message}")
    end
  end

  def with_expection_logging(&block)
    begin
      block.call
    rescue Exception => e
      BTLog.error("Expection #{e}")
      raise e
    end
  end
end
