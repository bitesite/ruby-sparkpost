module SparkPost
  class Client
    attr_reader :transmission
    attr_reader :template
    def initialize(options = {})
      @options = options
      @api_key = ENV['SPARKPOST_API_KEY']
      @api_host = ENV['SPARKPOST_API_HOST'] || 'https://api.sparkpost.com'

      raise ArgumentError, 'No API key is provided. Either provide
       api_key with constructor or set SPARKPOST_API_KEY environment
        variable' if @api_key.blank?

      raise ArgumentError, 'No API host is provided. Either provide
       api_host with constructor or set SPARKPOST_API_HOST environment
        variable' if @api_host.blank?
    end

    def transmission
      @transmission ||= Transmission.new(@api_key, @api_host, @options)
    end

    def template
      @template ||= Template.new(@api_key, @api_host, @options)
    end

    def suppression_list
      @suppression_list ||= SuppressionList.new(@api_key, @api_host, @options)
    end
  end
end
