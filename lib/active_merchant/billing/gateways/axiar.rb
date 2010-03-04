# Author:: Rob Aldred @ Setfire Media, http://setfiremedia.com

module ActiveMerchant
  module Billing
    class AxiarGateway < Gateway
      API_URL = 'https://api.axiarpayments.co.uk:8081/axiar'
      TDS_URL = 'https://api.axiarpayments.co.uk:8081/3dreturn'

      self.supported_cardtypes = [:visa, :master, :american_express, :discover, :jcb, :switch, :solo, :maestro, :diners_club]
      self.supported_countries = ['GB']
      self.default_currency = 'GBP'
      self.supports_3d_secure = true

      self.homepage_url = 'http://www.axiarpayments.co.uk/'
      self.display_name = 'Axiar'

      self.money_format = :cents
      # self.ssl_strict = false

      APPROVED = 'SUCCESS'

      REGISTER_TYPE = 'REGISTER'
      AUTH_TYPE = 'AUTH'
      CANCEL_TYPE = 'REVERSAL'
      FULFILL_TYPE = 'PREAUTH_SETTLE'
      PRE_TYPE = 'PREAUTH'
      REFUND_TYPE = 'REFUND'

      AVS_CVV_CODE = {
        "U" => 'X',
        "Y" => 'Y',
        "N" => 'N'
      }

      def initialize(options = {})
        requires!(options, :login, :password)
        @options = options
        super
      end
      
      def register(money, options = {})
        requires!(options, :order_id)
        commit(build_registration_request(REGISTER_TYPE, money, options))
      end

      def authorize(money, credit_card, options = {})
        requires!(options, :order_id)
        commit(build_authorisation_or_purchase_request(PRE_TYPE, money, credit_card, options))
      end

      def purchase(money, credit_card, options = {})
        requires!(options, :order_id)
        commit(build_authorisation_or_purchase_request(AUTH_TYPE, money, credit_card, options))
      end

      def capture(money, reference, options = {})
        requires!(options, :order_id)
        commit(build_void_or_capture_request(FULFILL_TYPE, money, reference, options))
      end

      def void(money, reference, options = {})
        requires!(options, :order_id)
        commit(build_void_or_capture_request(CANCEL_TYPE, money, reference, options))
      end

      def credit(money, credit_card, options = {})
        requires!(options, :order_id)
        commit(build_refund_request(money, credit_card, options))
      end

      # Completes a 3D Secure transaction
      def three_d_complete(pa_res, md)
        commit(build_3d_secure_complete_request({'PaRes' => pa_res, 'MD' => md}),true)
      end

      # Is the gateway running in test mode?
      def test?
        @options[:test] || super
      end

      def three_d_secure_enabled?
        @options[:enable_3d_secure]
      end

      private
      
        def build_registration_request(type, money, options)
          xml = Builder::XmlMarkup.new :indent => 2
          xml.instruct!
          xml.tag! :request do
            add_authentication(xml)

            xml.tag! :options do
              xml.tag! :type, type
            end
            
            xml.tag! :payment do
              add_customer_information(xml,options)
              add_total(xml,money)
            end
            
            xml.tag! :cart do
              xml.tag! :items, nil
              xml.tag! :cart_id, options[:order_id]
            end
          end
          xml.target!
        end

        def build_authorisation_or_purchase_request(type, money, credit_card, options)
          xml = Builder::XmlMarkup.new :indent => 2
          xml.instruct!
          xml.tag! :request do
            add_authentication(xml)

            xml.tag! :options do
              xml.tag! :type, type
              xml.tag! :parent_transaction, options[:parent_transaction]
              unless options[:skip_3d_secure] == true
                xml.tag! :td_secure, three_d_secure_enabled? ? 1 : ''
                xml.tag! :td_description, ''
              end
            end

            xml.tag! :payment do
              add_customer_information(xml,options)
              add_credit_card(xml, credit_card, options)
              add_total(xml,money)
            end

            xml.tag! :cart do
              xml.tag! :items, nil
              xml.tag! :cart_id, options[:order_id]
            end
          end
          xml.target!
        end

        def build_void_or_capture_request(type, money, authorization, options)
          xml = Builder::XmlMarkup.new :indent => 2
          xml.instruct!
          xml.tag! :request do
            add_authentication(xml)

            xml.tag! :options do
              xml.tag! :type, type
              xml.tag! :parent_transaction, authorization
            end

            xml.tag! :payment do
              add_customer_information(xml,options)
              add_total(xml,money)
            end

            xml.tag! :cart do
              xml.tag! :items, nil
              xml.tag! :cart_id, options[:order_id]
            end
          end
          xml.target!
        end

        def build_refund_request(money, credit_card, options)
          xml = Builder::XmlMarkup.new :indent => 2
          xml.instruct!
          xml.tag! :request do
            add_authentication(xml)

            xml.tag! :options do
              xml.tag! :type, REFUND_TYPE
            end

            xml.tag! :payment do
              add_customer_information(xml, options)
              add_credit_card(xml, credit_card, options)
              add_total(xml,money)
            end

            xml.tag! :cart do
              xml.tag! :items, nil
              xml.tag! :cart_id, options[:order_id]
            end
          end
          xml.target!
        end

        def build_3d_secure_complete_request(args)
          md = CGI.escape(args['MD'])
          pares = CGI.escape(args['PaRes'])
          return "MD=#{md}&PaRes=#{pares}"
        end

        def add_authentication(xml)
          xml.tag! :authorisation do
            xml.tag! :username, @options[:login]
            xml.tag! :password, @options[:password]
          end
        end

        def add_credit_card(xml, credit_card, options)

          xml.tag! :card do
            unless options[:card_token].blank?

              xml.tag! :tokenid, options[:card_token]

            else

              xml.tag! :number, credit_card.number
              xml.tag! :expiry do
                xml.tag! :month, sprintf('%02d',credit_card.month)
                xml.tag! :year, credit_card.year.to_s[-2,2]
              end

              # optional values - for UK Maestro/Solo etc
              if [ 'switch', 'solo' ].include?(card_brand(credit_card).to_s)              
                xml.tag! :issue do
                  xml.tag! :month, sprintf('%02d',credit_card.start_month) unless credit_card.start_month.blank?
                  xml.tag! :year, credit_card.start_year.to_s[-2,2] unless credit_card.start_year.blank?
                end              
                xml.tag! :issue_number, credit_card.issue_number unless credit_card.issue_number.blank?
              end
            end
            
            xml.tag! :cvv, credit_card.verification_value if credit_card.verification_value?
            
          end
        end
        
        def add_customer_information(xml,options)
          
          address = options[:billing_address] || options[:address]
          
          return unless address
          
          xml.tag! :name, options[:card_holder_name] unless options[:card_holder_name].blank?
          xml.tag! :company, address[:company] unless address[:company].blank?
          xml.tag! :email, options[:email] unless address[:email].blank?
          
          xml.tag! :address do        
            xml.tag! :address1, address[:address1] unless address[:address1].blank?
            xml.tag! :address2, address[:address2] unless address[:address2].blank?
            xml.tag! :address3, address[:address3] unless address[:address3].blank?
            xml.tag! :town, address[:city] unless address[:city].blank?
            xml.tag! :county, address[:city] unless address[:state].blank?
            xml.tag! :country, address[:country] unless address[:country].blank?
            xml.tag! :postcode, address[:zip] unless address[:zip].blank?
          end
        end

        def add_total(xml,money)
          xml.tag! :total, amount(money)
          xml.tag! :currency, 826
        end

        def commit(request,tds = false)
          url = tds ? TDS_URL : API_URL
          response = parse(ssl_post(url, request))

          if response[:avs_result]
            avs_result = {
               :street_match => AVS_CVV_CODE[response[:avs_result][1,1]],
               :postal_match => AVS_CVV_CODE[response[:avs_result][2,1]]
            }
            cvv_result = AVS_CVV_CODE[response[:avs_result][0,1]]
          end

          Response.new(response[:result] == APPROVED, response[:error_message] || response[:auth_message], response,
            :test => test?,
            :authorization => "#{response[:trx_id]};#{response[:auth_code]}",
            :avs_result => avs_result,
            :cvv_result => cvv_result,
            :three_d_secure => (response[:pareq] and response[:md] and response[:redirect_url]) ? true : false,
            :pa_req => response[:pareq],
            :md => response[:md],
            :acs_url => response[:redirect_url]
          )
        end

        def parse(body)

          response = {}
          xml = REXML::Document.new(body)
          root = REXML::XPath.first(xml, "//response")
          root = REXML::XPath.first(xml, "//tds_response") if root.nil?
          root = REXML::XPath.first(xml, "//error") if root.nil?

          root.elements.to_a.each do |node|
            parse_element(response, node)
          end

          response
        end 
        
        def parse_element(response, node)
          if node.has_elements?
            node.elements.each{|e| parse_element(response, e) }
          else
            response[node.name.underscore.to_sym] = node.text
          end
        end
    end
  end
end

