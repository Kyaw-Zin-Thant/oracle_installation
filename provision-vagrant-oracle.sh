#!/usr/bin/env bash


cat << EOF
***************************************

Installation d\'Oracle

@see http://dbaora.com/install-oracle-11g-release-2-11-2-on-centos-linux-7/
@see https://oracle-base.com/articles/misc/oui-silent-installations
@see https://gist.github.com/martndemus/7ad8209f9be9185bcf3a

***************************************
EOF

echo -e "\n--- Download Oracle repositoy ---\n"
curl -o /etc/yum.repos.d/oracle-linux.repo -LO http://yum.oracle.com/public-yum-ol7.repo > /dev/null 2>&1


echo -e "\n--- Installation d'Oracle repositoy ---\n"
echo -e "-> Installing dependances\n"
yum -y install --nogpgcheck oracle-rdbms-server-11gR2-preinstall > /dev/null 2>&1

echo -e "-> Disable Oracle Repo\n"
yum-config-manager --disable ol7_latest > /dev/null 2>&1
yum-config-manager --disable ol7_UEKR3 > /dev/null 2>&1
yum -y install glibc elfutils-libelf-devel unixODBC unixODBC-devel mksh compat-db compat-gcc-44 compat-gcc-44-c++ libaio.i686 libaio-devel.i686 binutils > /dev/null 2>&1

echo -e "-> Get Oracle JRE\n"
wget --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/8u60-b27/jre-8u60-linux-x64.rpm" > /dev/null 2>&1
yum -y localinstall jre-8u60-linux-x64.rpm > /dev/null 2>&1
rm jre-8u60-linux-x64.rpm


echo -e "-> Aliasing Oracle\n"
cat << EOF | sudo tee -a /etc/profile.d/oracle.sh
# Oracle Settings
export TMP=/tmp

export ORACLE_HOSTNAME=localhost
export ORACLE_UNQNAME=ORA11G
export ORACLE_BASE=/data/ora01/app/oracle
export ORACLE_HOME=\$ORACLE_BASE/product/11.2.0/db_1
export ORACLE_SID=ORA11G
export PATH=\$PATH:\$ORACLE_HOME/bin
export LD_LIBRARY_PATH=\$ORACLE_HOME/lib:/lib:/usr/lib;
export CLASSPATH=\$ORACLE_HOME/jlib:\$ORACLE_HOME/rdbms/jlib;

alias cdob='cd \$ORACLE_BASE'
alias cdoh='cd \$ORACLE_HOME'
alias tns='cd \$ORACLE_HOME/network/admin'
alias envo='env | grep ORACLE'

umask 022
EOF

source ~/.bashrc

mkdir -p /data/ora01/app/oracle/product/11.2.0/db_1
chown oracle:oinstall -R /data/ora01/app
chmod 775 -R /data/ora01/app


echo -e "-> Copy sources from srvDev\n Please Wait"

echo -en "\t - Copy 1 of 2 ..."
if [ ! -f /vagrant/vagrant/linux.x64_11gR2_database_1of2.zip ];
then
	echo -e " Error: You must dowload linux.x64_11gR2_database_1of2.zip"
	exit 1
fi

echo -en "\t - Copy 2 of 2 ..."
if [ ! -f /vagrant/vagrant/linux.x64_11gR2_database_2of2.zip ];
then
	echo -e " Error: You must dowload linux.x64_11gR2_database_2of2.zip"
	exit 1
fi

echo -e "-> extract oracle archives"

unzip /vagrant/vagrant/linux.x64_11gR2_database_1of2.zip -d /home/oracle > /dev/null 2>&1
unzip /vagrant/vagrant/linux.x64_11gR2_database_2of2.zip -d /home/oracle > /dev/null 2>&1

chown oracle:oinstall -R /home/oracle/database

echo -en "-> Installing Oracle ...\n"
su oracle <<EOF
cd /home/oracle/database
/home/oracle/database/runInstaller -silent -noconfig -waitforcompletion -ignorePrereq -responseFile /vagrant/vagrant/dotfiles/oracle_db_install.rsp > /dev/null 2>&1
EOF
source ~/.bashrc
echo -e "... Execute /data/ora01/app/oraInventory/orainstRoot.sh\n"
/data/ora01/app/oraInventory/orainstRoot.sh

echo -e "... Execute /data/ora01/app/oracle/product/11.2.0/db_1/root.sh\n"
/data/ora01/app/oracle/product/11.2.0/db_1/root.sh
source ~/.bashrc
/usr/bin/su oracle <<EOF

echo -n "-> Creating the Oracle listener ..."
 /data/ora01/app/oracle/product/11.2.0/db_1/bin/netca  /silent /responsefile /vagrant/vagrant/dotfiles/oracle_netca.rsp
EOF

/usr/bin/rm -rf /home/oracle/database