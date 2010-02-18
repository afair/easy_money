require 'rubygems'
require 'test/unit'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'easy_money'

class Test::Unit::TestCase
end

class Sample
  include EasyMoney
  attr_accessor :price, :balance
  easy_money :price
  easy_money :balance
end
