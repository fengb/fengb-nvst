class YearUserSummaryPresenter
  def initialize(year, user)
    @year = year
    @user = user
  end

  def starting_balance
    user_growth.value_at(start_date)
  end

  def contributions
    @contributions ||= Contribution.where(user: @user).year(@year).sum(:amount)
  end

  def gross_gains
    user_growth.gross_value_at(end_date) - contributions
  end

  def management_fee
    @management_fee ||= -user_growth.booked_fee_at(end_date)
  end

  def ending_balance
    user_growth.gross_value_at(end_date) + management_fee
  end

  private
  def user_growth
    @user_growth ||= YearUserGrowthPresenter.new(@year, @user)
  end

  def start_date
    Date.new(@year.to_i, 1, 1)
  end

  def end_date
    Date.new(@year.to_i, 12, 31)
  end
end
