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
    validate :user_by_username, unless: :sent_to_all_members?

    def execute
      recipients.each do |recipient|
        MessagesMailer.send_message(recipient, subject, body).deliver_later
      end
    end

    private

    def recipients
      emails = []
      emails << valid_user if valid_user.present?

      sent_to_all ? hub.users_with_roles.map(&:email) : emails
    end

    def valid_user
      User.find_by(username: to).try(&:email)
    end

    def sent_to_all_members?
      sent_to_all
    end

    def user_by_username
      return if valid_user.present?

      errors.add(:base, 'Please enter a valid username')
    end
  end
end
