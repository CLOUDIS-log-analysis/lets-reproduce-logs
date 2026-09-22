nix develop

git clone https://github.com/haproxy/haproxy
cd haproxy
git checkout v3.4-dev8

make clean
make -j $(nproc) TARGET=linux-glibc \
               USE_OPENSSL=1 USE_QUIC=1 USE_QUIC_OPENSSL_COMPAT=1 \
               USE_LUA=1 USE_PCRE2=1
cd ..

uftrace record -P. --srcline ./haproxy/haproxy -f segmentation-fault.cfg
uftrace replay --srcline -L 'src/*' -L 'include/*' > uftrace.log

