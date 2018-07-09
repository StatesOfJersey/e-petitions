#!/usr/bin/env bash
set -e
set -o pipefail

su - deploy <<'EOF'
rm -rf /home/deploy/<%= prefix %>/current/.bundle
rm -f /home/deploy/<%= prefix %>/current/log
rm -f /home/deploy/<%= prefix %>/current/tmp
rm -f /home/deploy/<%= prefix %>/current/vendor/bundle
rm -f /home/deploy/<%= prefix %>/current/public/assets
rm -f /home/deploy/<%= prefix %>/current/public/400.html
rm -f /home/deploy/<%= prefix %>/current/public/403.html
rm -f /home/deploy/<%= prefix %>/current/public/404.html
rm -f /home/deploy/<%= prefix %>/current/public/406.html
rm -f /home/deploy/<%= prefix %>/current/public/422.html
rm -f /home/deploy/<%= prefix %>/current/public/500.html
rm -f /home/deploy/<%= prefix %>/current/public/503.html
rm -f /home/deploy/<%= prefix %>/current/public/error.css
EOF
