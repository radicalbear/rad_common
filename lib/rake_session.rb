class RakeSession
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::DateHelper

  attr_accessor :time_limit, :status_frequency

  def initialize(time_limit, status_frequency)
    self.time_limit = time_limit
    self.status_frequency = status_frequency
  end

  def reset_status
    raise 'please set time_limit variable before running' unless time_limit

    @start_time = Time.current
    @counter = 0
  end

  def check_status(label, count)
    @counter += 1
    now = Time.current

    if @counter == 1 || (@counter % status_frequency == 0)
      elapsed = distance_of_time_in_words(@start_time, now, include_seconds: true)
      minutes = ((now - @start_time) / 60).ceil
      per_hour = ((@counter / minutes) * 60).ceil
      per_day = per_hour * 24

      if count
        if per_hour > 0
          count_label = "of #{count} "
          hours_remaining = (count - @counter) / (per_hour * 1.0)
          from_time = now
          finished_label = ", finished in #{distance_of_time_in_words(from_time, from_time + hours_remaining.hours)}"
        end

        puts "#{label} #{pluralize(@counter, 'items')} #{count_label}in #{pluralize(minutes, 'minute')}, #{per_hour} per hour, #{per_day} per day, elapsed: #{elapsed}#{finished_label}"
      else
        puts "#{label}, elapsed: #{elapsed}"
      end
    end

    (now - @start_time) > (time_limit - 3.minutes)
  end
end
