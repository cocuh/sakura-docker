docker pull cocuh/sakura-default
docker pull cocuh/sakura-years
docker pull cocuh/sakura-mandelbrot
docker pull cocuh/sakura-proxy
docker pull cocuh/dakko.site

echo "[starting]sakura_default"
docker rm -f sakura_default
docker run -d \
    --restart=always \
    --name sakura_default \
    cocuh/sakura-default

echo "[starting]sakura_years"
docker rm -f sakura_years
docker run -dit \
    --restart=always \
    --name sakura_years \
    -v /var/www/years \
    --read-only \
    cocuh/sakura-years \
    /bin/sh

echo "[starting]sakura_mandelbrot"
docker rm -f sakura_mandelbrot
docker run -dit \
    --restart=always \
    --name sakura_mandelbrot \
    -v /var/www/mandelbrot \
    --read-only \
    cocuh/sakura-mandelbrot \
    /bin/sh

echo "[starting]dakko.site"
docker rm -f dakko_site
docker run -dit \
    --restart=always \
    --name dakko_site \
    -v /var/www/dakko.site \
    --read-only \
    cocuh/dakko.site \
    /bin/sh

echo "[starting]sakura_proxy"
docker rm -f sakura_proxy
docker run -d \
    --restart=always \
    --name sakura_proxy \
    --volumes-from sakura_years \
    --volumes-from sakura_mandelbrot \
    --volumes-from dakko_site \
    --link sakura_default:default_typowriter \
    --link sakura_years:years_typowriter \
    --link sakura_mandelbrot:mandelbrot_typowriter \
    --link dakko_site:dakko_site \
    -p 80:80 \
    cocuh/sakura-proxy \

