FROM mcr.microsoft.com/playwright:v1.50.1-jammy
RUN npm install -g netlify-cli node-jq serve
