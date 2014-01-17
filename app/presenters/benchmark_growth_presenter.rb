class BenchmarkGrowthPresenter
  def initialize(investment, contributions, normalize_to: nil)
    @contributions = contributions.sort(&:date)
    @normalize_to = normalize_to
    @price_matcher = investment.price_matcher(@contributions.first.date)
    @share_matcher = BestMatchHash.sum(@contributions.map{|c| [c.date, c.amount / @price_matcher[c.date]]})
  end

  def dates
    # FIXME: defuglify
    @dates ||= Investment.benchmark.price_matcher(@contributions.first.date).keys
  end

  def value_at(date)
    normalized_weight * @price_matcher[date] * @share_matcher[date]
  end

  private
  def normalized_weight
    @normalized_weight ||= @normalize_to.nil? ? 1 : Rational(@normalize_to, @contributions.first.amount)
  end
end
