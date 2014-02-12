class TransactionsGrowthPresenter
  def self.all
    self.new(transactions: Transaction.includes(lot: :investment),
             cashflows:    Contribution.all + Expense.all)
  end

  def initialize(transactions: [],
                 cashflows:    [])
    @price_matchers = {}
    @shares_matchers = {}
    transactions.group_by(&:investment).each do |inv, transactions|
      @shares_matchers[inv] = BestMatchHash.sum(transactions.map{|t| [t.date, t.shares]})
    end
    @principal_matcher = BestMatchHash.sum(cashflows.map{|c| [c.date, c.amount]})
    @cashflow_amounts = {}
    cashflows.each do |cashflow|
      @cashflow_amounts[cashflow.date] ||= 0
      @cashflow_amounts[cashflow.date] += cashflow.amount
    end
  end

  def value_at(date)
    investments.sum{|i| value_for(i, date)}
  end

  def principal_at(date)
    @principal_matcher[date]
  end

  def cashflow_at(date)
    @cashflow_amounts[date] || 0
  end

  private
  def value_for(investment, date)
    shares = shares_for(investment, date)
    shares.zero? ? 0 : shares * price_for(investment, date)
  end

  def price_for(investment, date)
    price_matcher(investment)[date]
  end

  def shares_for(investment, date)
    @shares_matchers[investment][date]
  end

  def investments
    @shares_matchers.keys
  end

  def price_matcher(investment)
    @price_matchers[investment] ||= investment.price_matcher(first_date_for(investment))
  end

  def first_date_for(investment)
    @shares_matchers[investment].keys.first
  end
end
