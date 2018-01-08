require 'rest-client'
require 'json'
require 'base64'

module Abucoins
  class API
    attr_reader :passphrase,
                :key,
                :secret,
                :url

    def initialize(passphrase:, key:, secret:, url: 'https://api.abucoins.com')
      @passphrase = passphrase
      @key = key
      @secret = secret
      @url = url
    end

    def products
      get('/products')
    end

    def orders(args = {})
      get('/orders', params: args)
    end

    def order(id)
      get("/orders/#{id}")
    end

    def fills
      get('/fills')
    end

    def create_order(side:, hidden: false, time_in_force: nil, size:, price:, product_id:, type: 'limit', cancel_after: nil, post_only: nil)
      opts = {
        side: side,
        hidden: hidden,
        size: size,
        price: price,
        product_id: product_id,
        type: type
      }
      opts[:time_in_force] = time_in_force unless time_in_force.nil?
      opts[:cancel_after] = cancel_after unless cancel_after.nil?
      opts[:post_only] = post_only unless post_only.nil?
      order = post('/orders', opts)

      raise Abucoins::CreateOrderException.new(order['error'] || order['message']) unless order['id']

      order
    end

    def cancel_order(id)
      delete("/orders/#{id}")
    end

    def accounts
      get('/accounts')
    end

    private

    def signature(timestamp, verb, path, body)
      str = "#{timestamp}#{verb}#{path}#{body}"
      secret = Base64.decode64(@secret)
      hmac = OpenSSL::HMAC.digest('sha256', secret, str)
      Base64.encode64(hmac)
    end

    def get(path, opts = {})
      uri = URI.parse("#{@url}#{path}")
      uri.query = URI.encode_www_form(opts[:params]) if opts[:params]

      response = RestClient.get(uri.to_s, auth_headers(uri.request_uri, 'GET'))

      if !opts[:skip_json]
        JSON.parse(response.body)
      else
        response.body
      end
    end

    def post(path, payload, opts = {})
      data = JSON.unparse(payload)
      response = RestClient.post("#{@url}#{path}", data, auth_headers(path, 'POST', data))

      if !opts[:skip_json]
        JSON.parse(response.body)
      else
        response.body
      end
    end

    def delete(path, opts = {})
      response = RestClient.delete("#{@url}#{path}", auth_headers(path, 'DELETE'))

      if !opts[:skip_json]
        JSON.parse(response.body)
      else
        response.body
      end
    end

    def auth_headers(path, method, body = '')
      timestamp = Time.now.utc.to_i
      sign = signature(timestamp, method, path, body)

      {
        'Content-Type' => 'application/json',
        'AC-ACCESS-KEY' => @key,
        'AC-ACCESS-TIMESTAMP' => "#{timestamp}",
        'AC-ACCESS-PASSPHRASE' => @passphrase,
        'AC-ACCESS-SIGN' => sign,
      }
    end
  end
end
