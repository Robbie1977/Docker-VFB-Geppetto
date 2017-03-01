FROM slarson/virgo-tomcat-server:3.6.4-RELEASE-jre-7

MAINTAINER Robert Court "rcourt@ed.ac.uk"

USER root
RUN apt-get install maven

USER virgo

RUN export BRANCH=query && \
mkdir -p /home/virgo/geppetto && cd /home/virgo/geppetto && \
echo cloning required modules: && \
git clone git@github.com:openworm/org.geppetto.git && \
git clone git@github.com:openworm/org.geppetto.frontend.git && \
git clone git@github.com:VirtualFlyBrain/geppetto-vfb.git && \
git clone git@github.com:openworm/org.geppetto.core.git && \
git clone git@github.com:openworm/org.geppetto.model.git && \
git clone git@github.com:openworm/org.geppetto.datasources.git && \
git clone git@github.com:openworm/org.geppetto.model.neuroml.git && \
git clone git@github.com:openworm/org.geppetto.model.swc.git && \
git clone git@github.com:openworm/org.geppetto.simulation.git && \
git clone git@github.com:VirtualFlyBrain/uk.ac.vfb.geppetto.git && \
for folder in * ; do cd $folder; git checkout development; cd .. ; done && \
for folder in * ; do cd $folder; git checkout ${BRANCH} | : ; cd .. ; done  && \
echo Adding VFB initialisation... && \
mv geppetto-vfb org.geppetto.frontend/src/main/webapp/extensions/ && \
sed 's/true/false/g' org.geppetto.frontend/src/main/webapp/extensions/extensionsConfiguration.json | sed -e 's/geppetto-vfb\/ComponentsInitialization":\ false/geppetto-vfb\/ComponentsInitialization":\ true/g' > org.geppetto.frontend/src/main/webapp/extensions/NEWextensionsConfiguration.json && \
mv org.geppetto.frontend/src/main/webapp/extensions/NEWextensionsConfiguration.json org.geppetto.frontend/src/main/webapp/extensions/extensionsConfiguration.json && \
echo Updating Modules... && \
cd org.geppetto && \
MODULES="<modules>"; for folder in ../* ; do if [ "$folder" != "../org.geppetto" ]; then MODULES=${MODULES}"<module>$folder</module>" ; fi; done; MODULES=${MODULES}"</modules>"; echo "$MODULES" && \
echo "$MODULES" && \
sed '/modules/,/modules/c\PLACEHOLDER' pom.xml | sed -e 's@PLACEHOLDER@'"$MODULES"'@g' > NEWpom.xml && \
mv NEWpom.xml pom.xml && \
VERSION=$(cat pom.xml | grep version | sed -e 's/\///g' | sed -e 's/\ //g' | sed -e 's/\t//g' | sed -e 's/<version>/\"/g') && \
echo $VERSION && \
ART="" && \
cd .. && \
for folder in * ; do if [ "$folder" != "org.geppetto" ]; then ART=${ART}'<artifact type="bundle" name="'$folder'" version='$VERSION'/>' ; fi; done; echo "$ART" && \
sed 's/<!--//g' org.geppetto/geppetto.plan | sed -e 's/-->//g' | sed -e '/<artifact/c\' | sed -e 's@<\/@'"$ART"'<\/@g' > org.geppetto/NEWgeppetto.plan && \
mv org.geppetto/NEWgeppetto.plan org.geppetto/geppetto.plan && \
REPO='{"sourcesdir":"..//..//..//", "repos":['; for folder in * ; do if [ "$folder" != "org.geppetto" ]; then REPO=${REPO}'{"name":"'$folder'", "url":"", "auto_install":"yes"},' ; fi; done; REPO=$REPO]} ; REPO=${REPO/,]/]}; echo "$REPO" > org.geppetto/utilities/source_setup/config.json && \
cd /home/virgo/geppetto/org.geppetto && mvn install && chmod -R 777 /home/virgo/geppetto

RUN cd /home/virgo/geppetto/org.geppetto/utilities/source_setup && python update_server.py

CMD ["/bin/bash"]

