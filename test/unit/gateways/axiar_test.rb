require 'test_helper'

class AxiarTest < Test::Unit::TestCase
  def setup
    @gateway = AxiarGateway.new(
                 :login => 'test_streamline',
                 :password => 'password'
               )

    @credit_card = ActiveMerchant::Billing::CreditCard.new(
    :number => '4012001038443335',
    :month => 02,
    :year => 2012,
    :first_name => 'Bob',
    :last_name => 'Smith',
    :verification_value => '609',
    :type => 'visa'
    )

    @address = { 
     :name     => 'Mark McBride',
     :address1 => 'Flat 12/3',
     :address2 => '45 Main Road',
     :city     => 'London',
     :state    => 'None',
     :country  => 'GBR',
     :zip      => 'A987AA',
     :phone    => '(555)555-5555'
    }

    @options = {
     :order_id => generate_unique_id,
     :billing_address => @address
    }
  end
  
  def test_successful_purchase
    @gateway.expects(:ssl_post).returns(successful_purchase_response)
    
    assert response = @gateway.purchase(@amount, @credit_card, @options)
    assert_instance_of 
    assert_success response
    
    # Replace with authorization number from the successful response
    assert_equal '', response.authorization
    assert response.test?
  end

  def test_unsuccessful_request
    @gateway.expects(:ssl_post).returns(failed_purchase_response)
    
    assert response = @gateway.purchase(@amount, @credit_card, @options)
    assert_failure response
    assert response.test?
  end

  private
  
  # Place raw successful response from gateway here
  def successful_purchase_response
  end
  
  # Place raw failed response from gateway here
  def failed_purchase_response
  end
end
