class Contact < ActionMailer::Base
  default from: DEFAULT_SENDER

  def request_rights(params, hub)
    @hub = hub
    @params = params
    @hub_url = hub_url(@hub)
    mail(:to => @hub.owners.collect{|u| u.email})
  end

end
