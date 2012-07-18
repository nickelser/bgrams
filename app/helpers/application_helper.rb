module ApplicationHelper
  def browser_class
    ua = request.headers && request.headers["HTTP_USER_AGENT"]
    case ua
    when /Chrome/
      "chrome webkit"
    when /Apple/
      "safari webkit"
    when /Firefox/
      "firefox"
    when /MSIE/
      "ie"
    when /Gecko/
      "mozilla"
    else
      ""
    end
  end
end
