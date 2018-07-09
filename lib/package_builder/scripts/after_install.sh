#!/usr/bin/env bash
set -e
set -o pipefail

chown -R deploy:deploy /home/deploy/<%= prefix %>/releases/<%= release %>

su - deploy <<'EOF'
ln -nfs /home/deploy/<%= prefix %>/shared/tmp /home/deploy/<%= prefix %>/releases/<%= release %>/tmp
ln -nfs /home/deploy/<%= prefix %>/shared/log /home/deploy/<%= prefix %>/releases/<%= release %>/log
ln -nfs /home/deploy/<%= prefix %>/shared/bundle /home/deploy/<%= prefix %>/releases/<%= release %>/vendor/bundle
ln -nfs /home/deploy/<%= prefix %>/shared/assets /home/deploy/<%= prefix %>/releases/<%= release %>/public/assets
ln -s /home/deploy/<%= prefix %>/releases/<%= release %> /home/deploy/<%= prefix %>/current_<%= release %>
mv -Tf /home/deploy/<%= prefix %>/current_<%= release %> /home/deploy/<%= prefix %>/current
cd /home/deploy/<%= prefix %>/current && bundle install --without development test --deployment --quiet
cd /home/deploy/<%= prefix %>/current && bundle exec rake db:migrate
cd /home/deploy/<%= prefix %>/current && bundle exec rake assets:precompile
if [ ${SERVER_TYPE} = "worker" ] ; then cd /home/deploy/<%= prefix %>/current && bundle exec whenever -w ; else echo not running whenever ; fi
EOF
