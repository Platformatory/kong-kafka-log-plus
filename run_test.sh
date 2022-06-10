#./reload.sh
sleep 2
curl -v http://localhost:8000/route/42/search?q=foo -H "apikey:my-key"
