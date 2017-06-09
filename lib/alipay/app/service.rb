

module Alipay
  module App
    module Service
      ALIPAY_TRADE_APP_PAY_REQUIRED_PARAMS = %w( app_id biz_content notify_url )
      @@env ||= Rails.env if defined? Rails
      @@env ||= ENV['RACK_ENV']
      @@env ||= 'development'
      case @@env
      when 'production'
        @@gateway = 'https://openapi.alipay.com/gateway.do'
      else
        @@gateway = "https://openapi.alipaydev.com/gateway.do"
      end

      def self.alipay_trade_refund(params, options = {})
        conn = Faraday.new(url: @@gateway) do |faraday|
          faraday.request  :url_encoded                                         # form-encode POST params
          faraday.response :logger, ::Logger.new(STDOUT), :bodies => true       # log requests to STDOUT， for debug
          faraday.adapter  Faraday.default_adapter                              # make requests with Net::HTTP
        end

        params = Utils.stringify_keys(params)
        key = options[:key] || Alipay.key

        params = { 'method' => 'alipay.trade.refund',
                   'charset' => 'utf-8',
                   'version' => '1.0',
                   'timestamp' => Time.now.utc.strftime('%Y-%m-%d %H:%M:%S').to_s,
                   'sign_type' => 'RSA' }.merge(params)

        string = Alipay::App::Sign.params_to_sorted_string(params)
        sign = Alipay::Sign::RSA.sign(key, string)
        new_params = params.merge("sign" => sign)

        re = conn.get "", new_params
        result = ActiveSupport::JSON.decode(re.body)
      end

      def self.alipay_trade_app_pay(params, options = {})
        params = Utils.stringify_keys(params)
        Alipay::Service.check_required_params(params, ALIPAY_TRADE_APP_PAY_REQUIRED_PARAMS)
        key = options[:key] || Alipay.key

        params = {
          'method'         => 'alipay.trade.app.pay',
          'charset'        => 'utf-8',
          'version'        => '1.0',
          'timestamp'      => Time.now.utc.strftime('%Y-%m-%d %H:%M:%S').to_s,
          'sign_type'      => 'RSA'
        }.merge(params)

        string = Alipay::App::Sign.params_to_sorted_string(params)
        sign = CGI.escape(Alipay::Sign::RSA.sign(key, string))
        encoded_string = Alipay::App::Sign.params_to_encoded_string(params)

        %Q(#{encoded_string}&sign=#{sign})
      end
    end
  end
end
