# frozen_string_literal: true

# Hub owner can send message to any hub member
class MessagesController < ApplicationController
  before_action :find_hub

  def new
    render layout: request.xhr? ? false : 'tabs'
  end

  def create
    @message = Messages::Create.run(messages_attributes)

    if @message.valid?
      render(plain: '') && return
    else
      @message.errors
      render(plain: @message.errors.full_messages.join('<br/>'), status: :not_acceptable) && return
    end
  end

  private

  def message_params
    params.require(:message).permit(:subject, :to, :body, :sent_to_all)
  end

  def find_hub
    @hub = Hub.find(params[:hub_id])
    authorize @hub, :create_message?
  end

  def messages_attributes
    message_hash = message_params.merge!(hub: @hub)
    return message_hash if message_params[:to].present?

    message_hash[:to] = ''
    message_hash
  end
end
