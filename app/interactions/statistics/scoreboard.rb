# frozen_string_literal: true

module Statistics
  # Generate data for the hub scoreboard UI
  class Scoreboard < ActiveInteraction::Base
    object :hub, class: Hub
    string :sort, default: 'name'
    string :criteria, default: 'Past Day'
    string :type, default: 'users'

    def execute
      counts_by_user_id = count_taggings_by_user_id
      counts_by_tag_id = count_taggings_by_tag_id

      scoreboard_users = create_users_scoreboard(counts_by_user_id.keys)
      scoreboard_users = insert_user_counts(scoreboard_users, counts_by_user_id)
      scoreboard_users = insert_user_ranks(scoreboard_users)

      scoreboard_tags = create_tags_scoreboard(counts_by_tag_id.keys)
      scoreboard_tags = insert_tag_counts(scoreboard_tags, counts_by_tag_id)
      scoreboard_tags = insert_tag_ranks(scoreboard_tags)

      if type == 'users'
        sort_scoreboard_values(scoreboard_users.values)
      else
        sort_scoreboard_values(scoreboard_tags.values)
      end
    end

    private

    def set_criteria
      case criteria
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

    def count_taggings_by_user_id
      count_taggings :tagger_id
    end

    def count_taggings_by_tag_id
      count_taggings :tag_id
    end

    def count_taggings(grouping_object)
      ActsAsTaggableOn::Tagging
        .select('DISTINCT taggings.taggable_id')
        .where(
          context: "hub_#{hub.id}",
          created_at: set_criteria,
          tagger_type: 'User',
          taggable_type: 'FeedItem'
        )
        .group(grouping_object)
        .count
    end

    def create_users_scoreboard(user_ids)
      users = User.where(id: user_ids).pluck(:id, :username)

      users.each_with_object({}) do |(user_id, username), scoreboard|
        scoreboard[user_id] = { username: username }
      end
    end

    def insert_user_counts(scoreboard, counts_by_user_id)
      counts_by_user_id.each_with_object(scoreboard) do |(user_id, count), local_scoreboard|
        local_scoreboard[user_id][:count] = count
      end
    end

    def insert_user_ranks(scoreboard)
      sorted_scoreboard = scoreboard.sort_by { |_id, user| user[:count] }.reverse

      sorted_scoreboard.each_with_object(scoreboard).with_index do |((user_id), local_scoreboard), i|
        local_scoreboard[user_id][:rank] = i + 1
      end
    end

    def create_tags_scoreboard(tag_ids)
      tags = ActsAsTaggableOn::Tag.where(id: tag_ids).pluck(:id, :name)

      tags.each_with_object({}) do |(tag_id, name), scoreboard|
        scoreboard[tag_id] = { name: name }
      end
    end

    def insert_tag_counts(scoreboard, counts_by_tag_id)
      counts_by_tag_id.each_with_object(scoreboard) do |(tag_id, count), local_scoreboard|
        local_scoreboard[tag_id][:count] = count
      end
    end

    def insert_tag_ranks(scoreboard)
      sorted_scoreboard = scoreboard.sort_by { |_id, tag| tag[:count] }.reverse

      sorted_scoreboard.each_with_object(scoreboard).with_index do |((tag_id), local_scoreboard), i|
        local_scoreboard[tag_id][:rank] = i + 1
      end
    end

    def sort_scoreboard_values(scoreboard_values)
      scoreboard_values.sort_by do |row|
        sort == 'name' ? row[:username].downcase : row[:rank]
      end
    end
  end
end
