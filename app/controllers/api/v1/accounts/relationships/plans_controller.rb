# frozen_string_literal: true

module Api::V1::Accounts::Relationships
  class PlansController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :authenticate_with_token!
    before_action :set_account

    # GET /accounts/1/plan
    def show
      authorize @account
      @plan = @account.plan

      render jsonapi: @plan
    end

    # PUT /accounts/1/plan
    def update
      authorize @account

      @plan = Plan.find plan_params[:id]

      status = if @account.billing.canceled?
                 Billings::CreateSubscriptionService.call(
                   customer: @account.billing.customer_id,
                   plan: @plan.plan_id,
                   trial_end: 'now'
                 )
               else
                 Billings::UpdateSubscriptionService.call(
                   subscription: @account.billing.subscription_id,
                   plan: @plan.plan_id
                 )
               end

      if status
        if @account.billing.update(state: :pending) &&
           @account.update(plan: @plan)
          BroadcastEventService.call(
            event: "account.plan.updated",
            account: @account,
            resource: @plan
          )

          render jsonapi: @plan
        else
          render_unprocessable_resource @account
        end
      else
        if @account.billing.card.nil?
          render_unprocessable_entity(
            detail: "failed to update plan because a payment method is missing",
            source: { pointer: "/data/relationships/billing" }
          )
        else
          render_unprocessable_entity(
            detail: "failed to update #{@account.billing.state} plan because of a billing issue (check payment method)",
            source: { pointer: "/data/relationships/billing" }
          )
        end
      end
    end

    private

    def set_account
      @account = @current_account
    end

    typed_parameters transform: true do
      options strict: true

      on :update do
        param :data, type: :hash do
          param :type, type: :string, inclusion: %w[plan plans]
          param :id, type: :string
        end
      end
    end
  end
end
