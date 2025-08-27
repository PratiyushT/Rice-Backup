🔗 Zapier Integration Setup Guide
Overview
Your Mystery Artwork Marketplace automatically sends order data to Zapier when a customer completes a purchase. This allows you to:

Send confirmation emails
Update spreadsheets
Notify your team
Trigger fulfillment workflows
Connect to 5000+ apps
🔒 Security Enhancement
NEW: Your application now includes a shared secret key in webhook headers for enhanced security!

Headers Sent with Each Webhook:
Content-Type: application/json
X-Zapier-Secret: your-secret-key
User-Agent: Mystery-Artwork-Marketplace/1.0
📋 Data Sent to Zapier
When a customer makes a purchase, this data is sent:

{

  "tier": "Collector's Edition",

  "price": 50,

  "tip": 10,

  "total": 60,

  "email": "customer@example.com",

  "timestamp": "2024-07-29T15:30:45.123Z",

  "orderId": "ORDER-1722267045123-abc123def",

  "customerData": {

    "email": "customer@example.com",

    "artworkTier": "Collector's Edition",

    "features": [

      "Limited edition artwork",

      "Artist video message",

      "Numbered certificate",

      "Express shipping",

      "Museum-quality materials",

      "Protective sleeve"

    ]

  }

}
🚀 Quick Setup Steps
Step 1: Create a Zapier Account
Go to zapier.com
Sign up for a free account (or log in)
Step 2: Create a New Zap
Click "Create Zap"
Choose "Webhooks by Zapier" as the trigger app
Select "Catch Hook" as the trigger event
Click "Continue"
Step 3: Get Your Webhook URL
Zapier will generate a webhook URL like: https://hooks.zapier.com/hooks/catch/12345678/abcdef/
Copy this URL
Step 4: Configure Your App Security
In your project folder, copy .env.example to .env.local:
cp .env.example .env.local
Edit .env.local and replace the values:
NEXT_PUBLIC_ZAPIER_WEBHOOK_URL=https://hooks.zapier.com/hooks/catch/12345678/abcdef/
NEXT_PUBLIC_ZAPIER_SECRET_KEY=your-unique-secret-key-here
Generate a strong secret key (minimum 32 characters, use letters, numbers, and symbols)
Step 5: Verify Security in Zapier (IMPORTANT!)
In your Zap, after the webhook trigger, add a Filter step
Set the filter condition to:
Field: headers__X-Zapier-Secret
Condition: Exactly matches
Value: your-unique-secret-key-here (same as in your .env.local)
This ensures only requests with the correct secret key will trigger your automations
Step 6: Test the Integration
Restart your development server: bun dev
Go to your app and make a test purchase
Check Zapier - you should see:
The webhook data received
The X-Zapier-Secret header in the request
Your filter step passing (if configured)
Step 7: Set Up Your Action
Choose what happens when orders come in:

Gmail: Send confirmation email to customer
Google Sheets: Log order to spreadsheet
Slack: Notify your team
Airtable: Add to order database
Email by Zapier: Send custom emails
And 5000+ other apps!
🔐 Security Best Practices
Secret Key Guidelines
Length: Use at least 32 characters
Complexity: Mix uppercase, lowercase, numbers, and symbols
Uniqueness: Generate a unique key for this application
Privacy: Never share your secret key publicly or in code repositories
Example Strong Secret Key
MyArt2024!Secure#WebhookKey$Random789
Zapier Security Setup
Always use the Filter step to verify the X-Zapier-Secret header
Monitor your Zap history for unauthorized webhook attempts
Rotate your secret key periodically for enhanced security
Use HTTPS only (automatically enforced)
Header Verification in Zapier
In your Zapier filter step, check:

headers__X-Zapier-Secret exactly matches YOUR_SECRET_KEY
This prevents unauthorized webhooks from triggering your automations.

💡 Popular Automation Ideas
1. Secure Email Confirmation Flow
Trigger: Webhook (order received) Filter: Verify X-Zapier-Secret header Action: Gmail - Send email to customer with order details

2. Protected Order Tracking
Trigger: Webhook (order received) Filter: Verify X-Zapier-Secret header Action: Google Sheets - Add new row with order data

3. Authenticated Team Notifications
Trigger: Webhook (order received) Filter: Verify X-Zapier-Secret header Action: Slack - Send message to #orders channel

4. Secure Fulfillment Workflow
Trigger: Webhook (order received) Filter: Verify X-Zapier-Secret header Actions:

Add to Airtable order database
Send email to fulfillment team
Create task in project management tool
🧪 Testing Your Secure Integration
Security Testing Checklist
 Secret key configured in .env.local
 Filter step added in Zapier to verify header
 Test purchase triggers webhook with correct header
 Unauthorized requests (wrong/missing secret) are blocked
 All automations work only with valid secret key
Testing Process
Valid Request Test: Make a purchase from your app
Should trigger Zapier with correct secret header
Should pass filter and execute actions
Invalid Request Test: Try sending a webhook without the secret
Should be blocked by the filter step
Actions should not execute
🔍 Monitoring and Troubleshooting
In Zapier Dashboard
Zap History: View all webhook triggers and their headers
Filter Results: See which requests passed/failed security check
Task Usage: Monitor your automation usage
Error Logs: Debug webhook and security issues
Common Security Issues
Filter not working?

Check that header field name is exactly: headers__X-Zapier-Secret
Verify the secret key matches exactly (case-sensitive)
Ensure no extra spaces in the secret key
Webhook rejected?

Confirm secret key is set in .env.local
Restart your development server after changing environment variables
Check browser console for webhook errors
✅ Security Setup Checklist
 Strong secret key generated (32+ characters)
 Secret key configured in .env.local
 Zapier filter step added to verify X-Zapier-Secret header
 Test purchase completed with valid secret
 Verified unauthorized requests are blocked
 All automations working with security in place
 Secret key kept private and secure
🆘 Advanced Security
Environment-Specific Keys
Use different secret keys for development and production:

# Development
NEXT_PUBLIC_ZAPIER_SECRET_KEY=dev-secret-key-2024

# Production
NEXT_PUBLIC_ZAPIER_SECRET_KEY=prod-secret-key-2024-ultra-secure
Webhook Signature Validation (Future Enhancement)
Consider implementing HMAC signature validation for even stronger security.

🔐 Your mystery artwork orders are now securely authenticated with Zapier!