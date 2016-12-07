class PayuApi
  class << self
    @@mutex = Mutex.new

    def configure_for(community)

    end

    def reset_configurations
      @client = nil
    end

    def with_payu_config(community, &block)
      @@mutex.synchronize {
        configure_for(community)
        return_value = block.call
        reset_configurations()
        return return_value
      }
    end

    # def transaction_sale(community, options)
    #   with_payu_config(community) do
    #     payu_payment_account = options[:options][:payer]
    # end
  end
end
