#!/bin/bash

# Deploy the reset-password Edge Function to Supabase
echo "Deploying reset-password Edge Function..."

# Deploy the function
supabase functions deploy reset-password

echo "Reset-password function deployed successfully!"
echo "You can test it with:"
echo "curl -X POST 'https://your-project-ref.supabase.co/functions/v1/reset-password' \\"
echo "  -H 'Authorization: Bearer YOUR_ANON_KEY' \\"
echo "  -H 'Content-Type: application/json' \\"
echo "  -d '{\"email\":\"test@example.com\"}'"