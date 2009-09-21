# Author:: Rob Aldred @ Setfire Media, http://setfiremedia.com

module ActiveMerchant
  module Billing
    class AxiarGateway < Gateway
      TEST_URL = 'https://testapi.axiarpayments.co.uk:8081/'
      LIVE_URL = 'https://api.axiarpayments.co.uk:8081/'
      
      self.supported_cardtypes = [:visa, :master, :american_express, :discover, :jcb, :switch, :solo, :maestro, :diners_club]
      self.supported_countries = ['GB']
      self.default_currency = 'GBP'
      
      self.homepage_url = 'http://www.axiarpayments.co.uk/'
      self.display_name = 'Axiar'
      
      def initialize(options = {})
        requires!(options, :login, :password)
        @options = options
        super
      end  
      
      def authorize(money, creditcard, options = {})
        post = {}
        add_invoice(post, options)
        add_creditcard(post, creditcard)        
        add_address(post, creditcard, options)        
        add_customer_data(post, options)
        
        commit('authonly', money, post)
      end
      
      def purchase(money, creditcard, options = {})
        post = {}
        add_invoice(post, options)
        add_creditcard(post, creditcard)        
        add_address(post, creditcard, options)   
        add_customer_data(post, options)
             
        commit('sale', money, post)
      end                       
    
      def capture(money, authorization, options = {})
        commit('capture', money, post)
      end
    
      private                       
      
      def add_customer_data(post, options)
      end

      def add_address(post, creditcard, options)      
      end

      def add_invoice(post, options)
      end
      
      def add_creditcard(post, creditcard)      
      end
      
      def parse(body)
      end     
      
      def commit(action, money, parameters)
      end

      def message_from(response)
      end
      
      def post_data(action, parameters = {})
      end
    end
  end
end

