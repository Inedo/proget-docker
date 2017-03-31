FROM mono

EXPOSE 80

ENV PROGET_VERSION 4.7.9

RUN mkdir -p /usr/local/proget && curl "https://s3.amazonaws.com/cdn.inedo.com/downloads/proget-linux/ProGet.$PROGET_VERSION.tar.xz" | tar xvJC /usr/local/proget

ENV PROGET_DATABASE "Server=proget-postgres; Database=postgres; User Id=postgres; Password=;"

VOLUME /var/proget/packages

CMD sed -e "s/\\(<add key=\"InedoLib.DbConnectionString\" value=\"\\).*\\?\\(\"\\/>\\)/\\1$PROGET_DATABASE\\2/" -i /usr/local/proget/service/ProGet.Service.exe.config -i /usr/local/proget/web/Web.config \
&& mono /usr/local/proget/db/bmdbupdate.exe Update /Conn="$PROGET_DATABASE" /Init=yes \
&& exec mono /usr/local/proget/service/ProGet.Service.exe run --mode=both --urls=http://*:80/
