module QueriesHelper
  def emot_rate emot
    str = "(#{emot[:value] <= 0 ? emot[:value].round(2).to_s : "+" + emot[:value].round(2).to_s})"
    if emot[:rate] > 0
      str += "&uarr;"
    elsif emot[:rate] < 0
      str += "&darr;"
    end
    return str.html_safe
  end
end
