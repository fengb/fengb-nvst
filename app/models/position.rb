# Generated
class Position < ActiveRecord::Base
  extend Arlj

  belongs_to :investment
  has_many   :activities, ->{order('date')}

  validates :investment, presence: true

  scope :long,  ->{joins(:activities).merge(Activity.opening.buy)}
  scope :short, ->{joins(:activities).merge(Activity.opening.sell)}
  scope :open, ->(during: Date.current) do
    left_joins_aggregate(:activities, 'SUM(shares)' => 'outstanding_shares',
                         where: ['date <= ?', during]).
      where('outstanding_shares != 0')
  end

  def opening_activity
    activities.find(&:opening?)
  end

  def opening(attr, *args)
    opening_activity.send(attr, *args)
  end

  def long?
    opening_activity.buy?
  end

  def short?
    opening_activity.sell?
  end

  def outstanding_shares
    activities.sum('shares')
  end

  def current_price
    investment.current_price
  end

  def current_value
    current_price * outstanding_shares
  end

  def realized_gain
    activities.to_a.sum(&:realized_gain)
  end

  def unrealized_gain
    (current_price - opening(:adjusted_price)) * outstanding_shares
  end

  def unrealized_principal
    (outstanding_shares * opening(:adjusted_price)).abs
  end

  def unrealized_gain_percent
    unrealized_gain / unrealized_principal
  end
end
