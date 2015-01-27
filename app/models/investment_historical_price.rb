class InvestmentHistoricalPrice < ActiveRecord::Base
  belongs_to :investment

  validates :date,       presence: true
  validates :close,      presence: true
  validates :high,       presence: true
  validates :low,        presence: true
  validates :adjustment, presence: true

  scope :year_range, ->(end_date=Date.current) { where(date: (end_date - 365)..end_date) }

  scope :start_from, ->(start_date) do
    start_date_sql = self.select('MAX(date)').where('date <= ?', start_date).to_sql
    where("date >= (#{start_date_sql})")
  end

  def self.previous_of(date)
    where('date < ?', date).order('date DESC').first
  end

  def self.matcher(&block)
    block ||= ->(val){ val.adjusted(:close) }

    array = self.order('date').map do |historical_price|
      [historical_price.date, block.call(historical_price)]
    end
    BestMatchHash.new(array)
  end

  after_initialize do |record|
    record.adjustment ||= 1
  end

  def adjusted(attr)
    self[attr] * self.adjustment
  end
end
