FROM mono

EXPOSE 80

ARG PROGET_VERSION=5.1.20

RUN apt-get update && apt-get install xz-utils

RUN mkdir -p /usr/local/proget && curl -sSL "https://s3.amazonaws.com/cdn.inedo.com/downloads/proget-linux/ProGet.$PROGET_VERSION.tar.xz" | tar xJC /usr/local/proget

ENV PROGET_DATABASE "Server=proget-postgres; Database=postgres; User Id=postgres; Password=;"

VOLUME /var/proget/packages
VOLUME /var/proget/extensions
VOLUME /usr/share/Inedo/SharedConfig

CMD ([ -f /usr/share/Inedo/SharedConfig/ProGet.config ] || echo '<?xml version="1.0" encoding="utf-8"?><InedoAppConfig><ConnectionString>'"$PROGET_DATABASE"'</ConnectionString><WebServer Enabled="true" Urls="http://*:80/"/></InedoAppConfig>' > /usr/share/Inedo/SharedConfig/ProGet.config) \
&& mono /usr/local/proget/db/bmdbupdate.exe Update /Conn="$PROGET_DATABASE" /Init=yes \
&& exec mono /usr/local/proget/service/ProGet.Service.exe run --mode=both
