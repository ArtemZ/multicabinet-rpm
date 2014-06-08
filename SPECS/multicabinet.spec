Summary: Multicabinet Billing Webapp
Name: multicabinet
Version: 0.1
Release: 11
License: Restricted
Group: Applications/Financial
BuildRoot: %{_builddir}/%{name}-root
URL: http://netdedicated.net
Vendor: Netdedicated Solutions
Packager: Artem Zhirkov
Requires: java-1.7.0-openjdk, redhat-lsb

Prereq: /sbin/chkconfig, /bin/mktemp, /bin/rm, /bin/mv
Prereq: sh-utils, textutils, /usr/sbin/useradd

#Prefix: /usr/local
BuildArchitectures: noarch
%define tomcat 7.0.47
Source0: http://files.develdynamic.com/multicabinet-installer/distro/redhat-init.sh
Source1: http://files.develdynamic.com/ROOT.war
Source2: http://www.eu.apache.org/dist/tomcat/tomcat-7/v%{tomcat}/bin/apache-tomcat-%{tomcat}.tar.gz
Source3: http://files.develdynamic.com/multicabinet-installer/multicabinet2/tomcat/conf/server.xml
Source4: http://files.develdynamic.com/multicabinet-installer/multicabinet2/etc/multicabinet2.properties
Source5: http://files.develdynamic.com/multicabinet-installer/multicabinet2/etc/tomcat.conf


%description
Web application for billing purpoises

%prep

%build
pwd
%install
pwd
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/usr/local/multicabinet2/etc \
	 $RPM_BUILD_ROOT/usr/local/multicabinet2/logs \
	 $RPM_BUILD_ROOT/usr/local/multicabinet2/index \
	 $RPM_BUILD_ROOT/usr/local/multicabinet2/db
#logs
touch $RPM_BUILD_ROOT/usr/local/multicabinet2/logs/stacktrace.log
touch $RPM_BUILD_ROOT/usr/local/multicabinet2/logs/error.log
touch $RPM_BUILD_ROOT/usr/local/multicabinet2/logs/debug.log

#install sysvinit file
mkdir -p $RPM_BUILD_ROOT/etc/rc.d/init.d
install -pm 755 %{SOURCE0} $RPM_BUILD_ROOT/etc/rc.d/init.d/multicabinet

#install tomcat7 source
tar xzf %{SOURCE2} -C $RPM_BUILD_ROOT/usr/local/multicabinet2
mv $RPM_BUILD_ROOT/usr/local/multicabinet2/apache-tomcat-%{tomcat} $RPM_BUILD_ROOT/usr/local/multicabinet2/tomcat
rm -rf $RPM_BUILD_ROOT/usr/local/multicabinet2/tomcat/webapps/*
rm -f $RPM_BUILD_ROOT/usr/local/multicabinet2/tomcat/conf/server.xml
install -pm 644 %{SOURCE3} $RPM_BUILD_ROOT/usr/local/multicabinet2/tomcat/conf/server.xml

#install multicabinet war
mkdir $RPM_BUILD_ROOT/usr/local/multicabinet2/tomcat/multicabinet
install -pm 644 %{SOURCE1} $RPM_BUILD_ROOT/usr/local/multicabinet2/tomcat/multicabinet/ROOT.war

#install configuration files
install -pm 644 %{SOURCE4} $RPM_BUILD_ROOT/usr/local/multicabinet2/etc/multicabinet2.properties
install -pm 644 %{SOURCE5} $RPM_BUILD_ROOT/usr/local/multicabinet2/etc/tomcat.conf

%clean
rm -rf $RPM_BUILD_ROOT

%pre
getent group multicabinet >/dev/null || groupadd -r multicabinet
getent passwd multicabinet >/dev/null || useradd -r -g multicabinet -s /sbin/nologin \
        -c "Multicabinet Billing Webapp" multicabinet
exit 0
        

%post
# Register the httpd service
/sbin/chkconfig --add multicabinet
#replace hostname with output of hostname -i in 
HOSTIP=`hostname -i`
sed -i "s/hostname:6060/$HOSTIP:6060/g" /usr/local/multicabinet2/etc/multicabinet2.properties

%preun
if [ $1 = 0 ]; then
    /sbin/service multicabinet stop
    /sbin/chkconfig --del multicabinet
fi
rm -rf /usr/local/multicabinet2/tomcat/multicabinet/ROOT

%files
%defattr(-,multicabinet,multicabinet)
%dir /usr/local/multicabinet2/index
%dir /etc/rc.d/init.d
/etc/rc.d/init.d/multicabinet
%dir /usr/local/multicabinet2/logs
/usr/local/multicabinet2/logs/stacktrace.log
/usr/local/multicabinet2/logs/error.log
/usr/local/multicabinet2/logs/debug.log
%dir /usr/local/multicabinet2/etc
%dir /usr/local/multicabinet2/db
%dir /usr/local/multicabinet2/tomcat
%dir /usr/local/multicabinet2/tomcat/bin
%dir /usr/local/multicabinet2/tomcat/conf
%dir /usr/local/multicabinet2/tomcat/lib
%dir /usr/local/multicabinet2/tomcat/temp
%dir /usr/local/multicabinet2/tomcat/work
%dir /usr/local/multicabinet2/tomcat/multicabinet
/usr/local/multicabinet2/tomcat/lib/*
/usr/local/multicabinet2/tomcat/bin/*
/usr/local/multicabinet2/tomcat/conf/*
/usr/local/multicabinet2/tomcat/temp/*
/usr/local/multicabinet2/tomcat/LICENSE
/usr/local/multicabinet2/tomcat/RELEASE-NOTES
/usr/local/multicabinet2/tomcat/RUNNING.txt
/usr/local/multicabinet2/tomcat/NOTICE
/usr/local/multicabinet2/tomcat/multicabinet/ROOT.war
%config(noreplace) /usr/local/multicabinet2/etc/multicabinet2.properties
%config /usr/local/multicabinet2/etc/tomcat.conf
%changelog
* Mon Dec 2 2013 Artem Zhirkov
- SySVinit stuff
* Sun Dec 1 2013 Artem Zhirkov
- Created initial spec file