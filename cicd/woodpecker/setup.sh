#!/bin/bash
set -e

echo "Setting up Woodpecker CI..."

# Generate secrets
AGENT_SECRET=$(openssl rand -hex 32)
WEBHOOK_SECRET=$(openssl rand -hex 32)

# Update secrets file
sed -i "s/CHANGE_ME_GENERATE_WITH_OPENSSL/$AGENT_SECRET/g" secrets.yaml
sed -i "s/CHANGE_ME_SAME_AS_SERVER/$AGENT_SECRET/g" secrets.yaml
sed -i "s/CHANGE_ME_GENERATE_WITH_OPENSSL/$WEBHOOK_SECRET/g" secrets.yaml

echo "Generated secrets:"
echo "  Agent Secret: $AGENT_SECRET"
echo "  Webhook Secret: $WEBHOOK_SECRET"

echo ""
echo "Next steps:"
echo "1. Create a GitHub OAuth App at: https://github.com/settings/applications/new"
echo "   - Application name: Woodpecker CI"
echo "   - Homepage URL: https://ci.playablestories.ai"
echo "   - Authorization callback URL: https://ci.playablestories.ai/authorize"
echo ""
echo "2. Update secrets.yaml with your GitHub OAuth credentials"
echo ""
echo "3. Apply the configuration:"
echo "   kubectl apply -f namespace.yaml"
echo "   kubectl apply -f secrets.yaml"
echo "   kubectl apply -f server.yaml"
echo "   kubectl apply -f agent.yaml"
echo "   kubectl apply -f ingress.yaml"
echo ""
echo "4. Add webhook to your repository:"
echo "   - URL: https://ci.playablestories.ai/hook"
echo "   - Secret: $WEBHOOK_SECRET"
echo "   - Events: Push, Pull Request"