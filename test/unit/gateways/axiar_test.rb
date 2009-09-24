# Author:: Rob Aldred @ Setfire Media, http://setfiremedia.com
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
     :name     => 'Bob Smith',
     :address1 => '14 Main Road',
     :city     => 'Manchester',
     :country  => '826',
     :zip      => 'M211DD',
     :phone    => '01614445555'
    }

    @options = {
     :order_id => 'test',
     :billing_address => @address
    }
    
    @amount = 2200
  end
  
  def test_successful_purchase
    @gateway.expects(:ssl_post).returns(successful_purchase_response)
    
    assert response = @gateway.purchase(@amount, @credit_card, @options)
    assert_instance_of Response, response
    assert_success response
    assert response.test?
    assert_equal '0132902a116ba200020001;509426', response.authorization
  end

  def test_unsuccessful_request
    @gateway.expects(:ssl_post).returns(failed_purchase_response)
    
    assert response = @gateway.purchase(@amount, @credit_card, @options)
    assert_failure response
    assert response.test?
  end
  
  def test_error_response
    @gateway.expects(:ssl_post).returns(failed_purchase_response)
    
    response = @gateway.purchase(@amount, @credit_card, @options)
    assert_instance_of Response, response
    assert_failure response
    assert response.test?
    assert_equal 'The card was declined by the issuing bank.', response.message
  end
  
  def test_supported_countries
    assert_equal ['GB'], AxiarGateway.supported_countries
  end
  
  def test_supported_card_types
    assert_equal [:visa, :master, :american_express, :discover, :jcb, :switch, :solo, :maestro, :diners_club], AxiarGateway.supported_cardtypes
  end
  
  def test_purchase_with_missing_order_id_option
    assert_raise(ArgumentError){ @gateway.purchase(@amount, @credit_card, {}) }
  end
  
  def test_authorize_with_missing_order_id_option
    assert_raise(ArgumentError){ @gateway.authorize(@amount, @credit_card, {}) }
  end
  
  def test_purchase_does_not_raise_exception_with_missing_billing_address
    @gateway.expects(:ssl_post).returns(successful_purchase_response)
    #except method for Hash is part of active support included in gateway_support.rb
    assert @gateway.authorize(@amount, @credit_card, @options.except(:billing_address)).is_a?(ActiveMerchant::Billing::Response)
  end

  private
  
    def failed_purchase_response
      <<-XML
<response>
  <auth_code></auth_code>
  <avs_response></avs_response>
  <avs_result>UUU</avs_result>
  <card_type>mc</card_type>
  <cvv_response></cvv_response>
  <error_code>1001</error_code>
  <error_message>The card was declined by the issuing bank.</error_message>
  <result>DECLINED</result>
  <trx_id>0132902a116ba800020001</trx_id>
  <trx_token>0132902a0be1410001a</trx_token>
</response>
      XML
    end

    def successful_purchase_response
      <<-XML
<response>
  <auth_code>509426</auth_code>
  <avs_response>DATA NOT CHECKED</avs_response>
  <avs_result>UUU</avs_result>
  <card_type>mc</card_type>
  <result>SUCCESS</result>
  <trx_id>0132902a116ba200020001</trx_id>
  <trx_token>0132902a0be13e0001a</trx_token>
</response>
      XML
    end
end
