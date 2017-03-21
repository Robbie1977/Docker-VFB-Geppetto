FROM slarson/virgo-tomcat-server:3.6.4-RELEASE-jre-7

MAINTAINER Robert Court "rcourt@ed.ac.uk"

USER root
COPY apache-maven-3.3.9-bin.tar.gz /tmp/apache-maven-3.3.9-bin.tar.gz
RUN cd /opt/ \
&& tar -zxvf /tmp/apache-maven-3.3.9-bin.tar.gz

RUN chmod -R 777 /opt

RUN rm /bin/sh && ln -s /bin/bash /bin/sh && rm /bin/sh.distrib && ln -s /bin/bash /bin/sh.distrib

USER virgo

ENV PATH=/opt/apache-maven-3.3.9/bin/:$PATH

RUN mkdir -p /opt/geppetto

ENV BRANCH=development

ENV SERVER_HOME=/home/virgo/

RUN cd /opt/geppetto && \
echo cloning required modules: && \
git clone https://github.com/openworm/org.geppetto.git && \
git clone https://github.com/openworm/org.geppetto.frontend.git && \
git clone https://github.com/VirtualFlyBrain/geppetto-vfb.git && \
git clone https://github.com/openworm/org.geppetto.core.git && \
git clone https://github.com/openworm/org.geppetto.model.git && \
git clone https://github.com/openworm/org.geppetto.datasources.git && \
git clone https://github.com/openworm/org.geppetto.model.neuroml.git && \
git clone https://github.com/openworm/org.geppetto.model.swc.git && \
git clone https://github.com/openworm/org.geppetto.simulation.git && \
git clone https://github.com/VirtualFlyBrain/uk.ac.vfb.geppetto.git && \
for folder in * ; do cd $folder; git checkout development; cd .. ; done && \
for folder in * ; do cd $folder; git checkout ${BRANCH} | : ; cd .. ; done

RUN set -x && cd /opt/geppetto && \
echo Adding VFB initialisation... && \
mv geppetto-vfb org.geppetto.frontend/src/main/webapp/extensions/ && \
sed 's/true/false/g' org.geppetto.frontend/src/main/webapp/extensions/extensionsConfiguration.json | sed -e 's/geppetto-vfb\/ComponentsInitialization":\ false/geppetto-vfb\/ComponentsInitialization":\ true/g' > org.geppetto.frontend/src/main/webapp/extensions/NEWextensionsConfiguration.json && \
mv org.geppetto.frontend/src/main/webapp/extensions/NEWextensionsConfiguration.json org.geppetto.frontend/src/main/webapp/extensions/extensionsConfiguration.json

RUN sed -i "s|UA-45841517-1|UA-18509775-2|g" /opt/geppetto/org.geppetto.frontend/src/main/webapp/templates/dist/geppetto.vm && \
sed -i "s|UA-45841517-1|UA-18509775-2|g" /opt/geppetto/org.geppetto.frontend/src/main/webapp/templates/geppetto.vm

RUN echo Updating Modules... && \
cd /opt/geppetto/org.geppetto && \
MODULES="<modules>"; for folder in ../* ; do if [ "$folder" != "../org.geppetto" ]; then MODULES=${MODULES}"<module>$folder</module>" ; fi; done; MODULES=${MODULES}"</modules>"; echo "$MODULES" && \
echo "$MODULES" && \
sed '/modules/,/modules/c\PLACEHOLDER' pom.xml | sed -e 's@PLACEHOLDER@'"$MODULES"'@g' > NEWpom.xml && \
mv NEWpom.xml pom.xml

RUN cd /opt/geppetto/org.geppetto && \
VERSION=$(cat pom.xml | grep version | sed -e 's/\///g' | sed -e 's/\ //g' | sed -e 's/\t//g' | sed -e 's/<version>/\"/g') && \
echo $VERSION && \
ART="" && \
cd /opt/geppetto && \
for folder in * ; do if [ "$folder" != "org.geppetto" ]; then ART=${ART}'<artifact type="bundle" name="'$folder'" version='$VERSION'/>' ; fi; done; echo "$ART" && \
sed 's/<!--//g' org.geppetto/geppetto.plan | sed -e 's/-->//g' | sed -e '/<artifact/c\' | sed -e 's|<\/|'"$ART"'<\/|g' > org.geppetto/NEWgeppetto.plan && \
mv org.geppetto/NEWgeppetto.plan org.geppetto/geppetto.plan

RUN cd /opt/geppetto && \
REPO='{"sourcesdir":"..//..//..//", "repos":[' && \
for folder in * ; do if [ "$folder" != "org.geppetto" ]; then REPO=${REPO}'{"name":"'$folder'", "url":"", "auto_install":"yes"},' ; fi; done; REPO=$REPO']}' && \
REPO=${REPO/,]/]} && \
echo $REPO > org.geppetto/utilities/source_setup/config.json

RUN cd /opt/geppetto/org.geppetto && mvn install && chmod -R 777 /opt/geppetto

RUN cd /opt/geppetto/org.geppetto/utilities/source_setup && python update_server.py

RUN mkdir -p /opt/VFB

COPY startup.sh /opt/VFB/startup.sh

USER root
RUN chmod -R 777 /opt
USER virgo

ENTRYPOINT ["/opt/VFB/startup.sh"]
