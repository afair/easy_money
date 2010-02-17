require 'helper'

class TestEasyMoney < Test::Unit::TestCase

  def test_include
    sample = Sample.new
    flunk "no price_money method" unless sample.respond_to?(:price_money)
    flunk "no price_money= method" unless sample.respond_to?(:price_money=)
  end

  def test_method_money
    s = Sample.new
    [ 10000, 123456, 0, -1 -9876 ].each do |p|
      s.price = p
      m = s.price_money
      s.price_money = m
      flunk "Assignment error: p=#{p} m=#{m} price=#{s.price}" unless s.price = p
    end
  end

  def test_method_money=
    s = Sample.new
    { "0.00"=>0, "12.34"=>1234, "-1.2345"=>-123, "12"=>1200, "4.56CR"=>-456 }.each do |m,p|
      s.price_money = m
      flunk "Assignment error: p=#{p} m=#{m} price=#{s.price}" unless s.price = p
    end
  end

  def test_cents_to_money
    assert EasyMoney.cents_to_money(123) == '1.23'
    assert EasyMoney.cents_to_money(-12333) == '-123.33'
    assert EasyMoney.cents_to_money(0) == '0.00'
    assert EasyMoney.cents_to_money(nil, :nil=>'?') == '?'
    assert EasyMoney.cents_to_money(-1, :negative=>'%.2f CR') == '0.01 CR'
    assert EasyMoney.cents_to_money(0, :zero=>'free') == 'free'
    assert EasyMoney.cents_to_money(100, :unit=>'$') == '$1.00'
    assert EasyMoney.cents_to_money(100, :separator=>',') == '1,00'
    assert EasyMoney.cents_to_money(12345678900, :separator=>',', :delimiter=>'.') == '123.456.789,00'
    assert EasyMoney.cents_to_money(333, :precision=>3) == '0.333'
    assert EasyMoney.cents_to_money(111, :precision=>1) == '11.1'
    assert EasyMoney.cents_to_money(111, :precision=>0) == '111'
  end

  def test_money_to_cents
    assert EasyMoney.money_to_cents('1.23'        ) == 123
    assert EasyMoney.money_to_cents('0.00'        ) == 0
    assert EasyMoney.money_to_cents('-1.23'       ) == -123
    assert EasyMoney.money_to_cents('1.23 CR'     ) == -123
    assert EasyMoney.money_to_cents('$-2.34 CR'   ) == 234
    assert EasyMoney.money_to_cents('   1.234'    ) == 123
    assert EasyMoney.money_to_cents('$1'          ) == 100
    assert EasyMoney.money_to_cents('1'           ) == 100
    assert EasyMoney.money_to_cents('1,00', :separator=>',',:delimiter=>'.') == 100
    assert EasyMoney.money_to_cents('$123.456.789,00 CR', :separator=>',',:delimiter=>'.') == -12345678900
    assert EasyMoney.money_to_cents('4.44', :precision=>4 ) == 44400
    assert EasyMoney.money_to_cents('4.44', :precision=>0 ) == 4
  end
end
