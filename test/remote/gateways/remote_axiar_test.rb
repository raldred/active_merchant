# Author:: Rob Aldred @ Setfire Media, http://setfiremedia.com
require 'test_helper'

class RemoteAxiarTest < Test::Unit::TestCase

  def setup
    @gateway = AxiarGateway.new(fixtures(:axiar))
    
    @authorised_amount = 1000
    @referral_amount = 7500
    @declined_amount = 12000
    
    @mastercard = CreditCard.new(fixtures(:axiar_mastercard))
    @mastercard_address = fixtures(:axiar_mastercard_address)
    
    @visa = CreditCard.new(fixtures(:axiar_visa))
    @visa_address = fixtures(:axiar_visa_address)
    
    @solo = CreditCard.new(fixtures(:axiar_solo))
    @solo_address = fixtures(:axiar_solo_address)
    
    @options = { 
      :order_id => '1',
      :description => 'Store Purchase'
    }
  end
  
  def test_authorised_mastercard_purchase
    @options[:billing_address] = @mastercard_address
    assert response = @gateway.purchase(@authorised_amount, @mastercard, @options)
    assert_success response
    assert response.test?
    assert_equal 'SUCCESS', response.params['result']
  end
  
  def test_referred_mastercard_purchase
    @options[:billing_address] = @mastercard_address    
    assert response = @gateway.purchase(@referral_amount, @mastercard, @options)
    assert_failure response
    assert response.test?
    assert_equal 'REFERRED', response.params['result']
  end
  
  def test_declined_mastercard_purchase
    @options[:billing_address] = @mastercard_address    
    assert response = @gateway.purchase(@declined_amount, @mastercard, @options)
    assert_failure response
    assert_equal 'DECLINED', response.params['result']
  end
  
  def test_authorised_solo_purchase
    @options[:billing_address] = @solo_address
    assert response = @gateway.purchase(@authorised_amount, @solo, @options)
    assert_success response
    assert response.test?
    assert_equal 'SUCCESS', response.params['result']
  end
  
  def test_authorised_token_purchase
    @options[:billing_address] = @mastercard_address
    purchase = @gateway.authorize(@authorised_amount, @mastercard, @options)
    assert_success purchase
    assert purchase.test?
    
    @options[:card_token] = purchase.params['trx_token']
    card = CreditCard.new(:verification_value => @mastercard.verification_value)
    
    response = @gateway.purchase(@authorised_amount, card, @options)
    assert_success response
    assert response.test?
    assert_equal 'SUCCESS', response.params['result']
  end

  def test_authorize_and_capture
    @options[:billing_address] = @mastercard_address  
    assert auth = @gateway.authorize(@authorised_amount, @mastercard, @options)
    assert_success auth
    assert_equal 'SUCCESS', auth.params['result']
    assert auth.authorization
    assert capture = @gateway.capture(@authorised_amount, auth.params['trx_id'], @options)
    assert_success capture
  end
  
  def test_token_authorise
    @options[:billing_address] = @mastercard_address
    purchase = @gateway.authorize(@authorised_amount, @mastercard, @options)
    assert_success purchase
    assert purchase.test?
    
    @options[:card_token] = purchase.params['trx_token']
    card = CreditCard.new(:verification_value => @mastercard.verification_value)
    
    response = @gateway.authorize(@authorised_amount, card, @options)
    assert_success response
    assert response.test?
    assert_equal 'SUCCESS', response.params['result']
  end
  
  
  def test_successfully_purchase_and_void
    purchase = @gateway.purchase(@authorised_amount, @mastercard, @options)
    assert_success purchase
    assert purchase.test?

    void = @gateway.void(@authorised_amount, purchase.params['trx_id'], @options)
    assert_success void
    assert void.test?
  end
  
  def test_all_match_avs
    @options[:billing_address] = @mastercard_address
    assert response = @gateway.purchase(@authorised_amount, @mastercard, @options)
    assert_success response
    assert response.test?
    assert_equal 'SUCCESS', response.params['result']
    assert_equal 'Y', response.avs_result['postal_match']
    assert_equal 'Y', response.avs_result['street_match']
    assert_equal 'Y', response.cvv_result['code']
  end

  def test_missing_login
    gateway = AxiarGateway.new(
                :login => '',
                :password => ''
              )
    assert response = gateway.purchase(@authorised_amount, @mastercard, @options)
    assert_failure response
    assert_equal 'Authentication Missing', response.message
  end
  
  def test_invalid_login
    gateway = AxiarGateway.new(
                :login => 'testinvalid',
                :password => 'testinvalid'
              )
    assert response = gateway.purchase(@authorised_amount, @mastercard, @options)
    assert_failure response
    assert_equal 'Invalid User and/or Password', response.message
  end
  
  def test_invalid_verification_number
    @mastercard.verification_value = 123
    response = @gateway.purchase(@authorised_amount, @mastercard, @options)
    assert_success response
    assert response.test?
    assert_equal 'N', response.cvv_result['code']
  end
  
  def test_invalid_expiry_month
    @options[:billing_address] = @mastercard_address
    @mastercard.month = 13
    response = @gateway.purchase(@authorised_amount, @mastercard, @options)
    assert_failure response
    assert_equal 'An error occured whilst trying to process payment, expiry month too large.', response.message
    assert response.test?
  end

  def test_invalid_expiry_year
    @options[:billing_address] = @mastercard_address
    @mastercard.year = 1999
    response = @gateway.purchase(@authorised_amount, @mastercard, @options)
    assert_failure response
    assert_equal 'The card has expired.', response.message
    assert response.test?
  end
  
  def test_successful_refund_with_credit_card
    response = @gateway.credit(@authorised_amount, @mastercard, @options)
    assert_success response
    assert response.test?
    assert !response.params['trx_id'].blank?
  end
  
  def test_successful_refund_with_token
    purchase = @gateway.purchase(@authorised_amount, @mastercard, @options)
    assert_success purchase
    assert purchase.test?
    
    @options[:card_token] = purchase.params['trx_token']
    card = CreditCard.new(:verification_value => @mastercard.verification_value)
    
    response = @gateway.credit(@authorised_amount, card, @options)
    assert_success response
    assert response.test?
    assert_equal 'SUCCESS', response.params['result']
    assert_equal 'Refund Accepted', response.params['auth_message']
  end
  
end
