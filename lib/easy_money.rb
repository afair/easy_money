# EasyMoney - Ruby class mixin library to add money helpers to attribute/methods
module EasyMoney

  def self.included(base) #:nodoc:
    base.extend( ClassMethods )
  end

  module ClassMethods

    # Creates an money instance method for the given method, named "#{method}_money" which returns
    # a formatted money string, and a #{method}_money= method used to set an edited money string.
    # The original method stores the value as integer (cents, or other precision/currency setting). Options:
    # * :money_method - Use this as the alternative name to the money-access methods
    # * :units - Use this as an alternative suffix name to the money methods ('dollars' gives 'xx_dollars')
    # * :precision - The number of digits implied after the decimal, default is 2
    # * :separator - The character to use after the integer part, default is '.'
    # * :delimiter - The character to use between every 3 digits of the integer part, default none
    # * :positive - The sprintf format to use for positive numbers, default is based on precision
    # * :negative - The sprintf format to use for negative numbers, default is same as :positive
    # * :zero - The sprintf format to use for zero, default is same as :positive
    # * :nil - The sprintf format to use for nil values, default none
    # * :unit - Prepend this to the front of the money value, say '$', default none
    # * :blank - Return this value when the money string is empty or has no digits on assignment
    # * :negative_regex - A Regular Expression used to determine if a number is negative (and without a - sign)
    #
    def easy_money(method, *args)
      opt = args.last.is_a?(Hash) ? args.pop : {}
      money_method = opt.delete(:money_method) || "#{method}_#{opt.delete(:units)||'money'}"

      class_eval %Q(
      def #{money_method}(*args)
        opt = args.last.is_a?(Hash) ? args.pop : {}
        EasyMoney.integer_to_money( #{method}, #{opt.inspect}.merge(opt))
      end

      def #{money_method}=(v, *args)
        opt = args.last.is_a?(Hash) ? args.pop : {}
        self.#{method} = EasyMoney.money_to_integer( v, #{opt.inspect}.merge(opt))
      end
      )
    end
  end

  # Returns the money string of the given integer value. Uses relevant options from #easy_money
  def self.integer_to_money(value, *args)
    opt = args.last.is_a?(Hash) ? args.pop : {}
    opt[:positive] ||= "%.#{opt[:precision]||2}f"
    pattern = 
      if value.nil?
        value = 0
        opt[:nil] || opt[:positive]
      else
        case value <=> 0
        when 1 then opt[:positive]
        when 0 then opt[:zero] || opt[:positive]
        else  
          value = -value if opt[:negative] && opt[:negative] != opt[:positive]
          opt[:negative] || opt[:positive]
        end
      end
    value = self.format_money( value, pattern, opt)
    value = opt[:unit]+value if opt[:unit]
    value.gsub!(/\./,opt[:separator]) if opt[:separator]
    if opt[:delimiter] && (m = value.match(/^(\D*)(\d+)(.*)/))
      # Adapted From Rails' ActionView::Helpers::NumberHelper
      n = m[2].gsub(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1#{opt[:delimiter]}")
      value=m[1]+n+m[3]
    end
    value
  end

  def self.integer_to_float(value, *args)
    opt = args.last.is_a?(Hash) ? args.pop : {}
    return (opt[:blank]||nil) if value.nil?
    value = 1.0 * value / (10**(opt[:precision]||2)) 
  end

  # Returns the integer of the given money string. Uses relevant options from #easy_money
  def self.money_to_integer(value, *args)
    opt = args.last.is_a?(Hash) ? args.pop : {}
    value.gsub!(opt[:delimiter],'') if opt[:delimiter]
    value.gsub!(opt[:separator],'.') if opt[:separator]
    value.gsub!(/^[^\d\.\-\,]+/,'')
    return (opt[:blank]||nil) unless value =~ /\d/
    m = value.to_s.match(opt[:negative_regex]||/^(-?)(.+\d)\s*cr/i)
    value = value.match(/^-/) ? m[2] : "-#{m[2]}" if m && m[2]

    # Money string ("123.45") to proper integer withough passing through the float transformation
    match = value.match(/(-?\d*)\.?(\d*)/)
    return 0 unless match
    value = match[1].to_i * (10 ** (opt[:precision]||2))
    cents = match[2]
    cents = cents + '0' while cents.length < (opt[:precision]||2)
    cents = cents.to_s[0,opt[:precision]||2]
    value += cents.to_i * (value<0 ? -1 : 1)
    value
  end

  # Returns the integer (cents) value from a Float
  def self.float_to_integer(value, *args)
    opt = args.last.is_a?(Hash) ? args.pop : {}
    return (opt[:blank]||nil) if value.nil?
    value = (value.to_f*(10**((opt[:precision]||2)+1))).to_i/10 # helps rounding 4.56 -> 455 ouch!
  end
  
  # Replacing the sprintf function to deal with money as float. "... %[flags]m ..."
  def self.format_money(value, pattern="%.2m", *args)
    opt = args.last.is_a?(Hash) ? args.pop : {}
    sign = value < 0 ? -1 : 1
    dollars, cents = value.abs.divmod( 10 ** (opt[:precision]||2))
    dollars *= sign
    parts = pattern.match(/^(.*)%([-\. \d+0]*)[fm](.*)/)
    return pattern unless parts
    intdec = parts[2].match(/(.*)\.(\d*)/)
    dprec, cprec = intdec ? [intdec[1], intdec[2]] : ['', '']
    dollars = sprintf("%#{dprec}d", dollars)
    cents = '0' + cents.to_s while cents.to_s.length < (opt[:precision]||2)
    cents = cents.to_s[0,cprec.to_i]
    cents = cents + '0' while cents.length < cprec.to_i
    value = parts[1] + "#{(dollars.to_i==0 && sign==-1) ? '-' : '' }#{dollars}#{cents>' '? '.':''}#{cents}" + parts[3]
    value
  end

end
