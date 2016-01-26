require 'test_helper'

describe 'dovetail-basic' do

  it 'test1' do
    'hello'.must_equal 'hello'
  end

  it 'test2' do
    'foo'.wont_equal 'bar'
  end

  it 'test3' do
    [1, 2, 3].wont_include 4
  end

end
