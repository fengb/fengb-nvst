require 'yahoo_finance'


class PopulateInvestmentsJob
  class << self
    def perform
      Investment.where(auto_update: true).each do |investment|
        self.new(investment).run!
      end
    end
  end

  def initialize(investment)
    @investment = investment
    @latest_date = InvestmentPrice.where(investment: @investment).order('date DESC').pluck(:date).first || Date.new
  end

  def run!
    ActiveRecord::Base.transaction do
      prices!
      dividends!
      splits!
    end
  end

  def prices!
    YahooFinance.historical_prices(@investment.symbol).each do |row|
      return if row.date <= @latest_date

      InvestmentPrice.create!(investment: @investment,
                              date:       row.date,
                              high:       row.high,
                              low:        row.low,
                              close:      row.close)
    end
  end

  def dividends!
    YahooFinance.dividends(@investment.symbol).each do |row|
      return if row.date <= @latest_date

      InvestmentDividend.create!(investment: @investment,
                                 date:       row.date,
                                 amount:     row.amount)
    end
  end

  def splits!
    YahooFinance.splits(@investment.symbol).each do |row|
      return if row.date <= @latest_date

      InvestmentSplit.create!(investment: @investment,
                              date:       row.date,
                              before:     row.before,
                              after:      row.after)
    end
  end
end
