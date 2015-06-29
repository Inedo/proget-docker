FROM debian:wheezy

RUN groupadd -r postgres && useradd -r -g postgres -s /bin/bash postgres

RUN apt-get update \
 && apt-get install -y locales \
 && rm -rf /var/lib/apt/lists/* \ 
 && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8 

ENV LANG en_US.utf8
ENV PG_MAJOR 9.4
ENV PG_VERSION 9.4.4-1.pgdg70+1

RUN apt-key adv --keyserver pool.sks-keyservers.net --recv-keys B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8 \
 && echo 'deb http://apt.postgresql.org/pub/repos/apt/ wheezy-pgdg main' $PG_MAJOR > /etc/apt/sources.list.d/pgdg.list \
 && apt-get update \
 && apt-get install -y postgresql-common \
 && sed -ri 's/#(create_main_cluster) .*$/\1 = false/' /etc/postgresql-common/createcluster.conf \ 
 && apt-get install -y postgresql-$PG_MAJOR=$PG_VERSION \ 
 && rm -rf /var/lib/apt/lists/*

RUN apt-key adv --keyserver pgp.mit.edu --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF \
 && echo "deb http://download.mono-project.com/repo/debian wheezy main" > /etc/apt/sources.list.d/mono-xamarin.list \
 && apt-get update \
 && apt-get install -y --fix-missing mono-devel \
 && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/run/postgresql && chown -R postgres /var/run/postgresql

ENV PATH /usr/lib/postgresql/$PG_MAJOR/bin:$PATH
ENV PGDATA /var/lib/postgresql/data
VOLUME /var/lib/postgresql/data



COPY proget_start.sh /proget_start.sh

EXPOSE 80
ENV MONO_IOMAP case

ENV PROGET_VERSION 4.0.1

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
