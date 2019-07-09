require 'sinatra'
require 'stripe'

# Read variables from your environment
Stripe.api_key = ENV['STRIPE_KEY']

# You can find your endpoint's secret in your webhook settings
endpoint_secret = ENV['STRIPE_ENDPOINT_SECRET']

# Using Sinatra, listen for a POST to the /webhook endpoint
post '/webhook' do
  # Retrieve the payload from the webhook
  payload = request.body.read

  # Verify signature to make sure the event came from Stripe
  signature = request.env['HTTP_STRIPE_SIGNATURE']
  event = nil

  begin
    event = Stripe::Webhook.construct_event(payload, signature, endpoint_secret)
    # Only respond to `charge.succeeded` events with a charge amount
    if event.type == 'charge.succeeded' && event.data.object.amount
    end
    status 200
  rescue JSON::ParserError => e
    # Invalid payload
    # If this happens, log the problem to investigate
    status 400
  rescue Stripe::SignatureVerificationError => e
    # Invalid signature
    # If this happens, log the problem to investigate
    status 400
  end
end