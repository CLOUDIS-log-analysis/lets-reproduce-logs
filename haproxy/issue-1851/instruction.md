nix develop

git clone https://github.com/haproxy/haproxy
cd haproxy
git checkout 6aec1f380e095cc36b279c4c9e1a955d01d41f6c~

make clean
make -j $(nproc) TARGET=linux-glibc \
               USE_OPENSSL=1 USE_QUIC=1 USE_QUIC_OPENSSL_COMPAT=1 \
               USE_LUA=1 USE_PCRE2=1
cd ../haproxy-test

python3 -m http.server 8080 --bind 127.0.0.1


uftrace record -P. --srcline ./haproxy/haproxy -db -f config.cfg

curl --http3 -k https://127.0.0.1:30443

uftrace replay --srcline -L 'src/*' -L 'include/*' > uftrace.log

