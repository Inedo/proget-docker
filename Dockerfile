FROM mono

EXPOSE 80

ENV PROGET_VERSION 5.0.10

RUN apt-get update && apt-get install xz-utils

RUN mkdir -p /usr/local/proget && curl "https://s3.amazonaws.com/cdn.inedo.com/downloads/proget-linux/ProGet.$PROGET_VERSION.tar.xz" | tar xvJC /usr/local/proget

ENV PROGET_DATABASE "Server=proget-postgres; Database=postgres; User Id=postgres; Password=;"

VOLUME /var/proget/packages

CMD sed -e "s/\\(<add key=\"InedoLib.DbConnectionString\" value=\"\\).*\\?\\(\"\\/>\\)/\\1$(echo "$PROGET_DATABASE" | sed -e "s/&/&amp;/g" -e "s/</&lt;/" -e "s/>/&gt;/" -e "s/\"/&quot;/g" -e "s/'/&#39;/g" -e "s/\\\\/\\\\\\\\/g")\\2/" -i /usr/local/proget/service/App_appSettings.config -i /usr/local/proget/web/Web_appSettings.config \
&& mono /usr/local/proget/db/bmdbupdate.exe Update /Conn="$PROGET_DATABASE" /Init=yes \
&& exec mono /usr/local/proget/service/ProGet.Service.exe run --mode=both --urls=http://*:80/
