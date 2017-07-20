require 'net/http'
require 'uri'
require_relative '../core_extensions/object'
require_relative 'request'
require_relative 'exceptions'

module SparkPost
  class Transmission
    include Request

    def initialize(api_key, api_host)
      @api_key = api_key
      @api_host = api_host
      @base_endpoint = "#{@api_host}/api/v1/transmissions"
      @white_listed_emails = ENV['WHITE_LISTED_EMAILS'].present? ? ENV['WHITE_LISTED_EMAILS'].split(',') : []
    end

    def send_payload(data = {}, url = endpoint, method = 'POST')
      if data.present? && data[:recipients].present?
        data[:recipients].each do |recipient|
          recipient[:address][:email] = append_sink(recipient[:address][:email]) if recipient[:address].present?
        end
      end
      request(url, @api_key, data, method)
    end

    def send_message(to, from, subject, html_message = nil, **options)
      # TODO: add validations for to, from
      html_message = content_from(options, :html) || html_message
      text_message = content_from(options, :text) || options[:text_message]
      content_options = options.delete(:content) || {}

      if html_message.blank? && text_message.blank?
        raise ArgumentError, 'Content missing. Either provide html_message or
         text_message in options parameter'
      end

      options_from_args = {
        recipients: prepare_recipients(to),
        content: content_options.merge(
          from: from,
          subject: subject,
          text: options.delete(:text_message),
          html: html_message
        ),
        options: {}
      }

      options.merge!(options_from_args) { |_k, opts, _args| opts }
      add_attachments(options)

      send_payload(options)
    end

    def prepare_recipients(recipients)
      recipients = [recipients] unless recipients.is_a?(Array)
      recipients.map { |recipient| prepare_recipient(recipient) }
    end

    private

    def add_attachments(options)
      if options[:attachments].present?
        options[:content][:attachments] = options.delete(:attachments)
      end
    end

    def prepare_recipient(recipient)
      if recipient.is_a?(Hash)
        raise ArgumentError,
              "email missing - '#{recipient.inspect}'" unless recipient[:email]
        recipient[:email] = append_sink(recipient[:email])
        { address: recipient }
      else
        { address: { email: append_sink(recipient) } }
      end
    end

    def append_sink(email)
      if ENV['SINK_EMAILS'] == 'true'
         if @white_listed_emails.include?(email)
           email
         else
           "#{email}.sink.sparkpostmail.com"
         end
      else
        email
      end
    end

    def content_from(options, key)
      (options || {}).fetch(:content, {}).fetch(key, nil)
    end
  end
end
