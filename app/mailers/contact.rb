class Contact < ActionMailer::Base
  default from: DEFAULT_SENDER

  def request_rights(params, hub)
    @hub = hub
    @params = params
    mail(:to => @hub.owners)
  end

end
