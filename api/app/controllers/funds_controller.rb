class FundsController < ApplicationController
  # GET /funds
  def index
    if params[:currency].present?
      funds = Fund.includes(:bank)
        .order('aligned_at desc')
        .where(amount_currency: params[:currency])

      if params[:trend] == 'monthly'
        funds = funds.group_by_month(:aligned_at, format: '%Y-%m').sum(:amount_cents)
        funds = [].tap do |trend|
          funds.each do |k, v|
            trend << {
              date: k,
              amount: Money.new(v, params[:currency]).to_f
            }
          end
        end
      end
    else
      funds = Fund.includes(:bank).order('aligned_at desc')
    end

    render json: funds
  end

  # POST /funds
  def create
    bank = Bank.find(fund_params[:bank_id])
    fund = bank.funds.new(fund_params.except(:bank_id))

    if fund.save
      render json: fund, status: :created, location: fund
    else
      render json: fund.errors, status: :unprocessable_entity
    end
  end

  private

  def fund_params
    params.require(:fund).permit(:aligned_at, :amount_currency, :amount_cents, :bank_id)
  end
end
