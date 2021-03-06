require 'httparty'
module SolutionsInfini
  class Sms

    include HTTParty

    # base_uri "http://alerts.solutionsinfini.com/api/v3/index.php"
    BASE_URL = "http://alerts.solutionsinfini.com/api/v3/index.php"

    def initialize; end

    def self.send_sms(params_hash={})
      #usage: SolutionsInfini::Sms.send_sms({to: '9xxxxxxx', body: "welcome to mysite"})
      self.new.send_sms(params_hash)
    end

    def send_sms(params_hash={})
      errors = []
      if valid?(params_hash, errors)
        #submit request to provider
        response = HTTParty.post("#{BASE_URL}", body: {method: :sms, api_key: SolutionsInfini.si_api_key, to: params_hash[:to], sender: SolutionsInfini.si_sender, message: params_hash[:body], format: :json})
        handle_response_on_send(response)
      else
        #raise error saying params not valid
        raise SolutionsInfini::ParamsError, errors
      end
    end

    def self.details(params_hash={})
      self.new.details(params_hash)
    end

    def details(params_hash)
      if params_hash[:sid].present?
        #get status from provider
        response = HTTParty.post("#{BASE_URL}", body: {method: "sms.status", api_key: SolutionsInfini.si_api_key, format: :json, id: params_hash[:sid]})
        handle_response_on_status(response)
      else
        #raise invalid argument error
        raise SolutionsInfini::ParamsError, "sid is mandatory"
      end
    end

    private

      def valid?(params_hash, errors)
        if !(params_hash[:to].present? && params_hash[:to].length >= 10)
          errors << "to number should be at least 10 digits"
        end
        if params_hash[:body].blank?
          errors << "body cannot be empty"
        end
        res = errors.blank? ? true : false
        return res
      end

      def handle_response_on_send(response)
        res = response.parsed_response
        case res["status"]
        when "OK" then OpenStruct.new({sid: res["data"]["0"]["id"]})
        else
          raise SolutionsInfini::UnexpectedError, res
        end
      end

      def handle_response_on_status(response)
        res = response.parsed_response
        case res["status"]
        when "OK" then
          data = res["data"].first
          OpenStruct.new({sid: data["id"], status: data["status"], number: data["mobile"], sent_at: data["senttime"], delivered_at: data["dlrtime"]})
        else
          raise SolutionsInfini::UnexpectedError, res
        end
      end

  end

end
