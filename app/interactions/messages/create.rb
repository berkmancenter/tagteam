# frozen_string_literal: true

module Messages
  # method to create/validate the messages
  class Create < ActiveInteraction::Base
    object :hub
    string :subject
    string :body
    string :to
    boolean :sent_to_all

    validates :subject, :body, presence: true
    validates :to, presence: true, unless: :sent_to_all_members?
    validates_format_of :to, with: /\A[^@\s]+@([^@\s]+\.)+[^@\s]+\z/, unless: :sent_to_all_members?

    def execute
      MessagesMailer.send_message(recipients, subject, body).deliver_later
    end

    private

    def recipients
      sent_to_all ? hub.users_with_roles.map(&:email) : to
    end

    def sent_to_all_members?
      sent_to_all
    end
  end
end
