FROM inedo/progetbase:latest

COPY nginx_default /etc/nginx/sites-enabled/default
COPY nginx_fastcgi_params /etc/nginx/fastcgi_params

COPY proget_start.sh /proget_start.sh

EXPOSE 80
ENV MONO_IOMAP case

ENV PROGET_VERSION 4.0.0

RUN apt-get update \
 && apt-get install -y wget bzip2 \
 && mkdir /usr/local/proget \
 && wget "https://s3.amazonaws.com/cdn.inedo.com/downloads/proget-linux/proget$PROGET_VERSION.tar.bz2" \
 && tar -xvj -C /usr/local/proget -f "proget$PROGET_VERSION.tar.bz2" \
 && rm "proget$PROGET_VERSION.tar.bz2" \
 && apt-get purge -y wget bzip2 \
 && apt-get autoremove -y \
 && rm -rf /var/lib/apt/lists/*

VOLUME /var/proget/packages

RUN chmod +x /proget_start.sh
ENTRYPOINT exec /proget_start.sh
