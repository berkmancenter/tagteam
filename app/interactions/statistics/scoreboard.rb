# frozen_string_literal: true

module Statistics
  class Scoreboard < ActiveInteraction::Base
    object :hub, class: Hub
    string :sort, default: 'name'
    string :criteria, default: 'Past Day'

    def execute
      users = @hub.users_with_roles.map { |u| { id: u.id, first_name: u.first_name, last_name: u.last_name } }

      taggings = ActsAsTaggableOn::Tagging.where(created_at: set_criteria)

      users.each do |user|
        user[:count] = taggings.where(
          tagger_type: User.name,
          tagger_id: user[:id],
          taggable_type: 'FeedItem'
        ).count
      end

      users.sort_by do |user|
        if @sort == 'name'
          [user[:first_name], user[:last_name]]
        else
          user.count
        end
      end
    end

    private

    def set_criteria
      case @criteria
      when 'Past Day'
        1.day.ago.beginning_of_day..1.day.ago.end_of_day
      when 'Week'
        1.week.ago.beginning_of_day..(1.week.ago + 7.days).end_of_day
      when 'Month'
        1.month.ago.beginning_of_day..(1.week.ago + 30.days).end_of_day
      when 'Year'
        1.year.ago.beginning_of_day..(1.year.ago + 365.days).end_of_day
      end
    end
  end
end
