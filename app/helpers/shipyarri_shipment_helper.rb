module ShipyarriShipmentHelper
  SHIPYARRI_USERNAME = "demoAVNBIZ"
  SHIPYARRI_CLIENTID = "1413"
  SHIPYARRI_PARENTID = "333"
  SHIPYARRI_URL = "http://avnbiz.co.in/test/AVNBIZ/webservice/test_upload_consignment.php"

  def self.get_label_from_shipyarri(tx_id, schedule_pickup_date)
    buyer_address = ShippingAddress.where("transaction_id = #{tx_id} and address_type = 'buyer'").first
    seller_address = ShippingAddress.where("transaction_id = #{tx_id} and address_type = 'seller'").first
    transaction = Transaction.find(tx_id)
    buyer_email = Email.where("person_id = '#{transaction.starter_id}' and confirmed_at is not null").first
    seller_email = Email.where("person_id = '#{transaction.listing_author_id}' and confirmed_at is not null").first
   
    weight = transaction.listing.category.weight.blank? ? "1" : "transaction.listing.category.weight"
    height = transaction.listing.category.height.blank? ? "10" : "transaction.listing.category.height"
    length = transaction.listing.category.length.blank? ? "10" : "transaction.listing.category.length"
    width = transaction.listing.category.width.blank? ? "10" : "transaction.listing.category.width"
 
    service_name = ""
    if transaction.listing.category.weight == 0.5 
      service_name = "Priority"
    elsif transaction.listing.category.weight == 1
      service_name = "Standard"
    else
      service_name = "Economy"
    end

    order_date = transaction.created_at.strftime('20%y-%m-%d').gsub('-','')

    params = {
      "username" => Base64.encode64("#{SHIPYARRI_USERNAME}"),
      "insurance" => Base64.encode64("yes"), 
      "order_id" => Base64.encode64("#{order_date}""#{transaction.id}"),
      "from_contact_number"=> Base64.encode64("#{seller_address.phone}"),
      "from_pincode"=> Base64.encode64("#{seller_address.postal_code}"),
      "from_landmark"=> Base64.encode64("#{seller_address.landmark}"),
      "from_address"=> Base64.encode64("#{seller_address.street1}"),
      "from_address2"=> Base64.encode64("#{seller_address.street2}"),
      "to_pincode"=> Base64.encode64("#{buyer_address.postal_code}"),
      "to_landmark"=> Base64.encode64("#{buyer_address.landmark}"),
      "to_address"=> Base64.encode64("#{buyer_address.street1}"),
      "to_address2"=> Base64.encode64("#{buyer_address.street2}"),
      "customer_name"=> Base64.encode64("#{buyer_address.name}"),
      "customer_email"=> Base64.encode64("#{buyer_email.address}"),
      "customer_contact_no"=> Base64.encode64("#{buyer_address.phone}"),
      "company_name"=> Base64.encode64("secondcry"), 
      "ship_date"=> Base64.encode64("#{schedule_pickup_date}"), 
      "no_of_packages"=> Base64.encode64("1"), 
      "package_type"=> Base64.encode64("identical"), 
      "package_content"=> Base64.encode64("products"), 
      "package_content_desc"=> Base64.encode64("Plastic goods"), 
      "total_invoice_value"=> Base64.encode64("#{transaction.unit_price}"), 
      "created_by"=> Base64.encode64("#{SHIPYARRI_CLIENTID}"),
      "avnkey"=> Base64.encode64("#{SHIPYARRI_CLIENTID}@#{SHIPYARRI_PARENTID}"), 
      "payment_mode"=> Base64.encode64("online"), 
      "package_name"=> Base64.encode64("#{service_name}"),
      "package_weight1"=>"#{weight}", 
      "package_height1"=>"#{height}", 
      "package_width1"=>"#{width}", 
      "package_length1"=>"#{length}", 
      "carrier_value1"=>"1", 
      "quantity1"=>"1",
      "partner_id"=> Base64.encode64("324")
    }

    uri = URI("#{SHIPYARRI_URL}")
    shipment_response = Net::HTTP.post_form(uri,params)
    response = JSON.parse(shipment_response.body)
    if response["status"] == 'success'
      transaction.tracking_number = response["tracking_number"]
      transaction.shipment_label_url = response["shipment_label"]
      transaction.order_status = 'shipment created'
      transaction.save
      message = Message.new
      message.conversation_id = transaction.conversation_id
      message.sender_id = transaction.listing_author_id
      message.content = "I have accepted the transaction and scheduled the pickup through Fedex, tracking No. #{response["tracking_number"]}. You can track the status of our shipment by clicking the button above."
      message.save
      MailCarrier.deliver_now(TransactionMailer.shipment_success_email_for_seller(transaction.shipment_label_url, seller_address.name, seller_email.address, "#{order_date}""#{transaction.id}"))
      MailCarrier.deliver_now(TransactionMailer.shipment_success_email_for_buyer(transaction.tracking_number, buyer_address.name, buyer_email.address, "#{order_date}""#{transaction.id}"))
    else
      transaction.order_status = 'order accepted'
      transaction.save
      message = Message.new
      message.conversation_id = transaction.conversation_id
      message.sender_id = transaction.listing_author_id
      message.content = "I would like to proceed with this transaction; however, there was an error in scheduling the pickup. I will contact Secondcry for further assistance."
      message.save
      MailCarrier.deliver_now(TransactionMailer.shipment_failure_email_seller(buyer_address.name, buyer_email.address, "#{order_date}""#{transaction.id}"))
    end
  end
end