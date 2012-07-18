$hash = Hash[ 1 => "one", 2 => "two", 3=> "three", 4 => "four", 5 => "five",
 6 => "six", 7 => "seven", 8 => "eight", 9 => "nine", 10 => "ten", 11 => "eleven", 12 => "twelve" , 13 => "thirteen",
 14 => "fourteen", 15 => "fifteen", 16 => "sixteen", 17 => "seventeen", 18 => "eighteen", 19 => "nineteen",
 20 => "twenty", 30=> "thirty", 40 =>"forty", 50 => "fifty", 60 => "sixty", 70 => "seventy", 80 =>"eighty",
 90 => "ninety", 100 => "hundred", 1000 => "thousand"]

class Integer
  def to_english
    str = ""
    tmp = self
    # billions
    if tmp >= 1000000000
      billions = tmp/1000000000
      str += billions.to_english + " billion"
      # if more than one, pluralize
      if tmp > 1
        str+= "s"
      end
      str += " "
      tmp = self - billions*1000000000
    end
    # millions
    if tmp >= 1000000
      millions = tmp/1000000
      str += millions.to_english + " million"
      # if more than one, pluralize
      if tmp > 1
        str += "s"
      end
      str += " "
      tmp = tmp - millions*1000000
    end
    # thousand (invariable noun)
    if tmp >= 1000
      thousands = tmp/1000
      str += thousands.to_english + " thousand "
      tmp = tmp - thousands*1000
    end
    # hundreds
    if tmp >= 100
      hundreds = tmp/100
      str += $hash[hundreds] + " hundred" 
      if (tmp-hundreds*100) > 0
        str += " and "
      end
      tmp = tmp - hundreds*100
    end
    
    if tmp > 0
      # numbers under twenty all have their little name.
      if tmp <= 19
        str += $hash[tmp]
      else 
        tenths = tmp
        tmp = tmp / 10
        if tmp > 0
          str += $hash[tmp*10]
        end
        if (tenths-tmp*10) > 0
          str += " " + $hash[tenths-tmp*10]
        end
      end
    end
    str
  end
end
