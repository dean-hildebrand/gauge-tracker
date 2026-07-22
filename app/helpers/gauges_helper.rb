module GaugesHelper
  # Human readable label for a single period range, chosen by the gauge's time_unit.
  def period_label(range, time_unit)
    case time_unit.to_sym
    when :daily   then range.first.to_fs(:long)
    when :weekly  then period_range_label(range)
    when :monthly then month_period_label(range)
    when :yearly  then year_period_label(range)
    end
  end

  private

  def month_period_label(range)
    full_month = range.first == range.first.beginning_of_month &&
                 range.last  == range.last.end_of_month
    full_month ? range.first.strftime("%B %Y") : period_range_label(range)
  end

  def year_period_label(range)
    full_year = range.first == range.first.beginning_of_year &&
                range.last  == range.last.end_of_year
    full_year ? range.first.strftime("%Y") : period_range_label(range)
  end

  # "14–20 Mar 2026" within one month/year, "28 Mar - 3 Apr 2026" across a boundary.
  def period_range_label(range)
    first, last = range.first, range.last

    if first.year == last.year && first.month == last.month
      "#{first.day}–#{last.day} #{last.strftime('%b %Y')}"
    elsif first.year == last.year
      "#{first.strftime('%-d %b')} – #{last.strftime('%-d %b %Y')}"
    else
      "#{first.strftime('%-d %b %Y')} – #{last.strftime('%-d %b %Y')}"
    end
  end
end
