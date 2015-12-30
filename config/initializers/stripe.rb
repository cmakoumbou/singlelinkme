Rails.configuration.stripe = {
  :publishable_key => ENV['PUBLISHABLE_KEY'],
  :secret_key      => ENV['SECRET_KEY']
}

Stripe.api_key = Rails.configuration.stripe[:secret_key]

if ENV.has_key?("STRIPE_WEBHOOK_SECRET")
  StripeEvent.authentication_secret = ENV['STRIPE_WEBHOOK_SECRET']
end

StripeEvent.configure do |events|
	events.subscribe 'invoice.payment_succeeded' do |event|
		customer = Stripe::Customer.retrieve(event.data.object.customer)
		sub = customer.subscriptions.retrieve(event.data.object.subscription)
		user_subscription = Subscription.find_by_customer_id(event.data.object.customer)

		if user_subscription.blank?
			user = User.find_by_email(customer.email)
			subscription = Subscription.new do |s|
				s.subscription_id = sub.id
				s.customer_id = sub.customer
				s.plan_id = sub.plan.id
				s.user = user
				s.start_date = Time.at(sub.current_period_start)
				s.end_date = Time.at(sub.current_period_end)
				s.status = "active"
			end
			subscription.save
		else
			user_subscription.subscription_id = sub.id
			user_subscription.plan_id = sub.plan.id
			user_subscription.start_date = Time.at(sub.current_period_start)
			user_subscription.end_date = Time.at(sub.current_period_end)
			user_subscription.status = "active"
			user_subscription.save
		end
	end

	events.subscribe 'invoice.payment_failed' do |event|
		next_payment_attempt = event.data.object.next_payment_attempt
		if next_payment_attempt.present?
			attempt_count = event.data.object.attempt_count
			user_subscription = Subscription.find_by_customer_id(event.data.object.customer)
			user = User.find_by_id(user_subscription.user_id)
			user_subscription.status = "past_due"
			user_subscription.next_payment_attempt = Time.at(event.data.object.next_payment_attempt)
			user_subscription.save
			UserMailer.failed_payment(user, next_payment_attempt, attempt_count).deliver
		end
	end

	events.subscribe 'customer.subscription.deleted' do |event|
		user_subscription = Subscription.find_by_customer_id(event.data.object.customer)
		if user_subscription.present?
			user = User.find_by_id(user_subscription.user_id)
			user_subscription.status = "canceled"
			user_subscription.save
			user.links.update_all(:disable => true)
			UserMailer.cancel_subscription(user).deliver
		end
	end

	events.subscribe 'customer.source.created' do |event|
		user_subscription = Subscription.find_by_customer_id(event.data.object.customer)
		user_subscription.last4 = event.data.object.last4
		user_subscription.save
	end
end