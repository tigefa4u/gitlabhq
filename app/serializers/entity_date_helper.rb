# frozen_string_literal: true

module EntityDateHelper
  include ActionView::Helpers::DateHelper
  include ActionView::Helpers::TagHelper

  def interval_in_words(diff)
    return 'Not started' unless diff

    distance_of_time_in_words(Time.now, diff, scope: 'datetime.time_ago_in_words')
  end

  # Converts seconds into a hash such as:
  # { days: 1, hours: 3, mins: 42, seconds: 40 }
  #
  # It returns 0 seconds for zero or negative numbers
  # It rounds to nearest time unit and does not return zero
  # i.e { min: 1 } instead of { mins: 1, seconds: 0 }
  def distance_of_time_as_hash(diff)
    diff = diff.abs.floor

    return { seconds: 0 } if diff == 0

    mins = (diff / 60).floor
    seconds = diff % 60
    hours = (mins / 60).floor
    mins = mins % 60
    days = (hours / 24).floor
    hours = hours % 24

    duration_hash = {}

    duration_hash[:days] = days if days > 0
    duration_hash[:hours] = hours if hours > 0
    duration_hash[:mins] = mins if mins > 0
    duration_hash[:seconds] = seconds if seconds > 0

    duration_hash
  end

  # Generates an HTML-formatted string for remaining dates based on start_date and due_date
  #
  # It returns "Past due" for expired entities
  # It returns "Upcoming" for upcoming entities
  # If due date is provided, it returns "# days|weeks|months remaining|ago"
  # If start date is provided and elapsed, with no due date, it returns "# days elapsed"
  def remaining_days_in_words(due_date, start_date = nil)
    if due_date&.past?
      content_tag(:strong, 'Past due')
    elsif start_date&.future?
      content_tag(:strong, 'Upcoming')
    elsif due_date&.today?
      content_tag(:strong, 'Today')
    elsif due_date
      if due_date.future?
        translate_time_remaining(due_date.end_of_day)
      else
        translate_time_ago(due_date.end_of_day)
      end.gsub(/\d+/) { |match| "<strong>#{match}</strong>" }.html_safe
    elsif start_date&.past?
      days = (Date.today - start_date).to_i
      "#{content_tag(:strong, days)} #{'day'.pluralize(days)} elapsed".html_safe
    end
  end

  def distance_in_time_for_translation(time)
    duration = ActiveSupport::Duration.build((time.to_time - Time.now).abs)
    midday_duration = ActiveSupport::Duration.build((time.midday.to_time - Time.now.midday).abs)
    if duration < 1.day
      { unit: :hours, count: (duration / 1.hour).round }
    elsif midday_duration <= 31.days
      { unit: :days, count: (midday_duration / 1.day).round }
    elsif duration < 12.months
      { unit: :months, count: (duration / 1.months).round }
    else
      { unit: :years, count: (duration / 1.year).round }
    end
  end

  def translate_time_ago(time)
    unit, count = distance_in_time_for_translation(time).values_at(:unit, :count)

    # Build translations explicitly for 'rake gettext:find'
    case unit
    when :hours
      n_('%d hour ago', '%d hours ago', count) % count
    when :days
      #t(:'datetime.time_ago_in_words.x_days', count: count)
      n_('%d day ago', '%d days ago', count) % count
    when :months
      #t(:'datetime.time_ago_in_words.x_months', count: count)
      n_('%d month ago', '%d months ago', count) % count
    when :years
      n_('%d year ago', '%d years ago', count) % count
    end
  end

  def translate_time_remaining(time)
    unit, count = distance_in_time_for_translation(time).values_at(:unit, :count)

    # Build translations explicitly for 'rake gettext:find'
    case unit
    when :hours
      n_('%d hour remaining', '%d hours remaining', count) % count
    when :days
      n_('%d day remaining', '%d days remaining', count) % count
    when :months
      n_('%d month remaining', '%d months remaining', count) % count
    when :years
      n_('%d year remaining', '%d years remaining', count) % count
    end
  end
end
