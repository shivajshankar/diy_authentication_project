nohup socat TCP-LISTEN:3000,fork,reuseaddr TCP:localhost:30001 > socat3000.log 2>&1 &
nohup socat TCP-LISTEN:8080,fork,reuseaddr TCP:localhost:30002 > socat8080.log 2>&1 &

