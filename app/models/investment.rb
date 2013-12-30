class Investment < ActiveRecord::Base
  has_many :prices,    class_name: 'InvestmentPrice'
  has_many :dividends, class_name: 'InvestmentDividend'
  has_many :splits,    class_name: 'InvestmentSplit'

  def self.cash
    find_by(auto_update: false)
  end

  def title
    symbol
  end

  def price_matcher
    BestMatchHash.new(prices.pluck('date', 'close'))
  end

  def current_price
    prices.order('date').last.close
  end

  def year_high
    prices.year_range.maximum(:high)
  end

  def year_low
    prices.year_range.minimum(:low)
  end
end
