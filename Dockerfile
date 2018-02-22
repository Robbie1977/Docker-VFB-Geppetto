FROM slarson/virgo-tomcat-server:3.6.4-RELEASE-jre-7

MAINTAINER Robert Court "rcourt@ed.ac.uk"

USER root
COPY apache-maven-3.3.9-bin.tar.gz /tmp/apache-maven-3.3.9-bin.tar.gz
RUN cd /opt/ \
&& tar -zxvf /tmp/apache-maven-3.3.9-bin.tar.gz

RUN chmod -R 777 /opt

RUN apt-get update --fix-missing && apt-get install -y sshfs

RUN rm /bin/sh && ln -s /bin/bash /bin/sh && rm /bin/sh.distrib && ln -s /bin/bash /bin/sh.distrib

USER virgo

ENV PATH=/opt/apache-maven-3.3.9/bin/:$PATH

#ENV JAVA_OPTS='-Dhttps.protocols=TLSv1.1,TLSv1.2'

RUN mkdir -p /opt/geppetto

ENV BRANCH=query

ENV SERVER_HOME=/home/virgo/

RUN cd /opt/geppetto && \
echo cloning required modules: && \
git clone https://github.com/openworm/org.geppetto.git && \
git clone https://github.com/openworm/org.geppetto.frontend.git && \
git clone https://github.com/VirtualFlyBrain/geppetto-vfb.git && \
git clone https://github.com/openworm/org.geppetto.core.git && \
git clone https://github.com/openworm/org.geppetto.model.git && \
git clone https://github.com/openworm/org.geppetto.datasources.git && \
git clone https://github.com/openworm/org.geppetto.model.swc.git && \
git clone https://github.com/openworm/org.geppetto.simulation.git && \
git clone https://github.com/VirtualFlyBrain/uk.ac.vfb.geppetto.git && \
for folder in * ; do cd $folder; git checkout development; cd .. ; done;

RUN cd /opt/geppetto/uk.ac.vfb.geppetto/ && git checkout development;

RUN sed -i 's/"css-loader": "\^0.28.7"/"css-loader": "0.28.7"/g' /opt/geppetto/org.geppetto.frontend/src/main/webapp/package.json
RUN sed -i "s|http.*/select|/solr/ontology/select|g" /opt/geppetto/geppetto-vfb/ComponentsInitialization.js

RUN sed -i "s|ontology_name:(fbbt)|ontology_name:(vfb)|g" /opt/geppetto/geppetto-vfb/ComponentsInitialization.js

RUN set -x && cd /opt/geppetto && \
echo Adding VFB initialisation... && \
mv geppetto-vfb org.geppetto.frontend/src/main/webapp/extensions/ && \
sed 's/geppetto-default\/ComponentsInitialization":\ true/geppetto-default\/ComponentsInitialization":\ false/g' org.geppetto.frontend/src/main/webapp/GeppettoConfiguration.json | sed -e 's/geppetto-vfb\/ComponentsInitialization":\ false/geppetto-vfb\/ComponentsInitialization":\ true/g' > org.geppetto.frontend/src/main/webapp/NEWGeppettoConfiguration.json && \
mv org.geppetto.frontend/src/main/webapp/NEWGeppettoConfiguration.json org.geppetto.frontend/src/main/webapp/GeppettoConfiguration.json

RUN grep -rnwl '/opt/geppetto/' -e "UA-45841517-1" | xargs sed -i "s|UA-45841517-1|UA-18509775-2|g" 

ADD pom.xml /opt/geppetto/org.geppetto/pom.xml.temp
ADD geppetto.plan /opt/geppetto/org.geppetto/geppetto.plan

ADD GeppettoConfiguration.json /opt/geppetto/org.geppetto.frontend/src/main/webapp/GeppettoConfiguration.json

RUN echo Updating Modules... && \
cd /opt/geppetto/org.geppetto && \
cat pom.xml && \
VERSION=$(cat pom.xml | grep version | sed -e 's/\///g' | sed -e 's/\ //g' | sed -e 's/\t//g' | sed -e 's/<version>//g') && \
echo "$VERSION" && \
mv pom.xml.temp pom.xml && \
sed -i "s@%VERSION%@${VERSION}@g" pom.xml && \
sed -i "s@%VERSION%@${VERSION}@g" geppetto.plan

RUN cat /opt/geppetto/org.geppetto/pom.xml && \
cat /opt/geppetto/org.geppetto/geppetto.plan

RUN cd /opt/geppetto && \
REPO='{"sourcesdir":"..//..//..//", "repos":[' && \
for folder in * ; do if [ "$folder" != "org.geppetto" ]; then REPO=${REPO}'{"name":"'$folder'", "url":"", "auto_install":"yes"},' ; fi; done; REPO=$REPO']}' && \
REPO=${REPO/,]/]} && \
echo $REPO > org.geppetto/utilities/source_setup/config.json

RUN cd /opt/geppetto/org.geppetto && mvn --quiet clean install

RUN cd /opt/geppetto/org.geppetto/utilities/source_setup && python update_server.py

RUN mkdir -p /opt/VFB

COPY startup.sh /opt/VFB/startup.sh

ENV MAXSIZE=5G

ENTRYPOINT ["/opt/VFB/startup.sh"]
