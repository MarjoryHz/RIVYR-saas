module ApplicationHelper
  def euro_display(value)
    value.to_s.gsub(/\bEUR\b/, "€")
  end
end
