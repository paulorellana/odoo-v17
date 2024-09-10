#!/bin/bash
#
# Script para instalar Odoo en Ubuntu 22.04
# Autor: SofBiz Technologies
#-------------------------------------------------------------------------------
# Este script instalará Odoo en tu servidor Ubuntu 22.04. Puede instalar múltiples instancias de Odoo
# en un solo Ubuntu debido a los diferentes puertos xmlrpc.
#-------------------------------------------------------------------------------
# PARA EJECUTAR EL SCRIPT SIGUE LOS SIGUIENTES PASOS:
# 1- Crea un nuevo archivo:
# sudo nano instalar_odoo17.sh
# 2- Coloca este contenido en él y luego dale los permisos adecuados:
# sudo chmod +x instalar_odoo17.sh
# 3- Ejecuta el script para instalar Odoo:
# ./instalar_odoo17.sh


OE_USER="odoo"
OE_HOME="/$OE_USER"
OE_HOME_EXT="/$OE_USER/${OE_USER}-server"
# El puerto predeterminado en el que se ejecutará esta instancia de Odoo (siempre y cuando uses el comando -c en la terminal)
# Establece en true si deseas instalarlo, false si no lo necesitas o ya lo tienes instalado.
INSTALL_WKHTMLTOPDF="True"
# Establece el puerto predeterminado de Odoo (aún debes usar -c /etc/odoo-server.conf, por ejemplo, para utilizar esto).
OE_PORT="8069"
# Elige la versión de Odoo que deseas instalar. Por ejemplo: 17.0, 16.0, 15.0 o saas-17. Cuando uses 'master', se instalará la versión principal.
# ¡IMPORTANTE! Este script contiene bibliotecas adicionales que son necesarias específicamente para Odoo 17.0.
OE_VERSION="17.0"
# Establece esto en True si deseas instalar la versión empresarial de Odoo.
IS_ENTERPRISE="False"
# Instala PostgreSQL V14 en lugar de la versión predeterminada (por ejemplo, V12 para Ubuntu 20/22) - esto mejora el rendimiento.
INSTALL_POSTGRESQL_FOURTEEN="True"
# Establece esto en True si deseas instalar Nginx.
INSTALL_NGINX="False"
# Establece la contraseña de superadministrador: si GENERATE_RANDOM_PASSWORD está configurado en "True", generaremos automáticamente una contraseña aleatoria, de lo contrario, usaremos esta.
OE_SUPERADMIN="admin"
# Establece "True" para generar una contraseña aleatoria, "False" para usar la variable OE_SUPERADMIN.
GENERATE_RANDOM_PASSWORD="True"
OE_CONFIG="${OE_USER}-server"
# Establece el nombre del sitio web.
WEBSITE_NAME="_"
# Establece el puerto de longpolling predeterminado de Odoo (aún debes usar -c /etc/odoo-server.conf, por ejemplo, para utilizar esto).
LONGPOLLING_PORT="8072"
# Establece "True" para instalar certbot y tener habilitado SSL, "False" para usar HTTP.
ENABLE_SSL="True"
# Proporciona el correo electrónico para registrar el certificado SSL.
ADMIN_EMAIL="info.sofbiz@gmail.com"
##
### Enlaces de descarga de WKHTMLTOPDF
## === Ubuntu Trusty x64 y x32 === (para otras distribuciones, por favor reemplaza estos dos enlaces
## para tener la versión correcta de wkhtmltopdf instalada; para obtener una nota de advertencia, consulta
## https://github.com/odoo/odoo/wiki/Wkhtmltopdf):
## https://www.odoo.com/documentation/16.0/administration/install.html

WKHTMLTOX_X64="https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.5/wkhtmltox_0.12.5-1.$(lsb_release -c -s)_amd64.deb"
WKHTMLTOX_X32="https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.5/wkhtmltox_0.12.5-1.$(lsb_release -c -s)_i386.deb"
#--------------------------------------------------
# Actualizar servidor
#--------------------------------------------------
echo -e "\n---- Actualizar servidor ----"
# el paquete universe es para Ubuntu 18.x
sudo add-apt-repository universe
# dependencia libpng12-0 para wkhtmltopdf
sudo add-apt-repository "deb http://mirrors.kernel.org/ubuntu/ xenial main"
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install libpq-dev

#--------------------------------------------------
# Instalar servidor PostgreSQL
#--------------------------------------------------
echo -e "\n---- Instalar servidor PostgreSQL ----"
if [ $INSTALL_POSTGRESQL_FOURTEEN = "True" ]; then
    echo -e "\n---- Installing postgreSQL V14 due to the user it's choise ----"
    sudo curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc|sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/postgresql.gpg
    sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
    sudo apt-get update
    sudo apt-get install postgresql-14
else
    echo -e "\n---- Instalación de la versión de postgreSQL predeterminada basada en la versión de Linux ----"
    sudo apt-get install postgresql postgresql-server-dev-all -y
fi


echo -e "\n---- Creación del usuario PostgreSQL de ODOO  ----"
sudo su - postgres -c "createuser -s $OE_USER" 2> /dev/null || true

#--------------------------------------------------
# Instalar dependencias
#--------------------------------------------------
echo -e "\n--- Instalación de Python 3 + pip3 --"
sudo apt-get install python3 python3-pip
sudo apt-get install git python3-cffi build-essential wget python3-dev python3-venv python3-wheel libxslt-dev libzip-dev libldap2-dev libsasl2-dev python3-setuptools node-less libpng-dev libjpeg-dev gdebi -y

echo -e "\n---- Instalar paquetes/requisitos de python ----"
sudo -H pip3 install -r https://github.com/odoo/odoo/raw/${OE_VERSION}/requirements.txt

echo -e "\n---- Instalación de nodeJS NPM y rtlcss para compatibilidad con LTR ----"
sudo apt-get install nodejs npm -y
sudo npm install -g rtlcss

#--------------------------------------------------
# Instale Wkhtmltopdf si es necesario
#--------------------------------------------------
if [ $INSTALL_WKHTMLTOPDF = "True" ]; then
  echo -e "\n---- Instale wkhtml y coloque accesos directos en el lugar correcto para ODOO 16 ----"
  #pick up correct one from x64 & x32 versions:
  if [ "`getconf LONG_BIT`" == "64" ];then
      _url=$WKHTMLTOX_X64
  else
      _url=$WKHTMLTOX_X32
  fi
  sudo wget $_url
  sudo gdebi --n `basename $_url`
  sudo ln -s /usr/local/bin/wkhtmltopdf /usr/bin
  sudo ln -s /usr/local/bin/wkhtmltoimage /usr/bin
else
  echo "¡Wkhtmltopdf no está instalado debido a la elección del usuario!"
fi

echo -e "\n---- Crear usuario del sistema ODOO ----"
sudo adduser --system --quiet --shell=/bin/bash --home=$OE_HOME --gecos 'ODOO' --group $OE_USER
# El usuario también debe agregarse al grupo sudo'ers.
sudo adduser $OE_USER sudo

echo -e "\n---- Crear directorio Log ----"
sudo mkdir /var/log/$OE_USER
sudo chown $OE_USER:$OE_USER /var/log/$OE_USER

#--------------------------------------------------
# Instalar ODOO
#--------------------------------------------------
echo -e "\n==== Instalación del servidor ODOO ===="
sudo git clone --depth 1 --branch $OE_VERSION https://www.github.com/odoo/odoo $OE_HOME_EXT/

if [ $IS_ENTERPRISE = "True" ]; then
    # ¡Instalación de Odoo Enterprise!
    sudo pip3 install psycopg2-binary pdfminer.six
    echo -e "\n--- Crear symlink para el nodo"
    sudo ln -s /usr/bin/nodejs /usr/bin/node
    sudo su $OE_USER -c "mkdir $OE_HOME/enterprise"
    sudo su $OE_USER -c "mkdir $OE_HOME/enterprise/addons"

    GITHUB_RESPONSE=$(sudo git clone --depth 1 --branch $OE_VERSION https://www.github.com/odoo/enterprise "$OE_HOME/enterprise/addons" 2>&1)
    while [[ $GITHUB_RESPONSE == *"Authentication"* ]]; do
        echo "------------------------ADVERTENCIA------------------------------"
        echo "¡Tu autenticación con Github ha fallado! Inténtalo de nuevo."
        printf "Para clonar e instalar la versión enterprise de Odoo, \necesita ser un partner oficial de Odoo y necesita acceso a\http://github.com/odoo/enterprise.\n"
        echo "CONSEJO: Presione ctrl+c para detener este script."
        echo "-------------------------------------------------------------"
        echo " "
        GITHUB_RESPONSE=$(sudo git clone --depth 1 --branch $OE_VERSION https://www.github.com/odoo/enterprise "$OE_HOME/enterprise/addons" 2>&1)
    done

    echo -e "\n---- Código de empresa agregado en $OE_HOME/enterprise/addons ----"
    echo -e "\n---- Instalación de bibliotecas específicas de Enterprise ----"
    sudo -H pip3 install num2words ofxparse dbfread ebaysdk firebase_admin pyOpenSSL
    sudo npm install -g less
    sudo npm install -g less-plugin-clean-css
fi

echo -e "\n---- Crear directorio de módulo personalizado ----"
sudo su $OE_USER -c "mkdir $OE_HOME/custom"
sudo su $OE_USER -c "mkdir $OE_HOME/custom/addons"

echo -e "\n---- Configuración de permisos en la carpeta de inicio ----"
sudo chown -R $OE_USER:$OE_USER $OE_HOME/*

echo -e "* Crear archivo de configuración del servidor"


sudo touch /etc/${OE_CONFIG}.conf
echo -e "* Creando el archivo de configuración del servidor"
sudo su root -c "printf '[options] \n; Esta es la contraseña que permite las operaciones de base de datos.:\n' >> /etc/${OE_CONFIG}.conf"
if [ $GENERATE_RANDOM_PASSWORD = "True" ]; then
    echo -e "* Generando contraseña de administrador aleatoria"
    OE_SUPERADMIN=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1)
fi
sudo su root -c "printf 'admin_passwd = ${OE_SUPERADMIN}\n' >> /etc/${OE_CONFIG}.conf"
if [ $OE_VERSION > "11.0" ];then
    sudo su root -c "printf 'http_port = ${OE_PORT}\n' >> /etc/${OE_CONFIG}.conf"
else
    sudo su root -c "printf 'xmlrpc_port = ${OE_PORT}\n' >> /etc/${OE_CONFIG}.conf"
fi
sudo su root -c "printf 'logfile = /var/log/${OE_USER}/${OE_CONFIG}.log\n' >> /etc/${OE_CONFIG}.conf"

if [ $IS_ENTERPRISE = "True" ]; then
    sudo su root -c "printf 'addons_path=${OE_HOME}/enterprise/addons,${OE_HOME_EXT}/addons\n' >> /etc/${OE_CONFIG}.conf"
else
    sudo su root -c "printf 'addons_path=${OE_HOME_EXT}/addons,${OE_HOME}/custom/addons\n' >> /etc/${OE_CONFIG}.conf"
fi
sudo chown $OE_USER:$OE_USER /etc/${OE_CONFIG}.conf
sudo chmod 640 /etc/${OE_CONFIG}.conf

echo -e "* Crear archivo de inicio"
sudo su root -c "echo '#!/bin/sh' >> $OE_HOME_EXT/start.sh"
sudo su root -c "echo 'sudo -u $OE_USER $OE_HOME_EXT/odoo-bin --config=/etc/${OE_CONFIG}.conf' >> $OE_HOME_EXT/start.sh"
sudo chmod 755 $OE_HOME_EXT/start.sh

#--------------------------------------------------
# Agregando ODOO como un Deamon (initscript)
#--------------------------------------------------

echo -e "* Crear archivo de inicio"
cat <<EOF > ~/$OE_CONFIG
#!/bin/sh
### COMENZAR INFORMACIÓN DE INICIO
# Proporciona: $OE_CONFIG
# Requerido-Inicio: \$remote_fs \$syslog
# Requerido-Parar: \$remote_fs \$syslog
# Debería-Iniciar: \$network
# Debería-Parar: \$network
# Predeterminaod-Inicio: 2 3 4 5
# Predeterminado-Parar: 0 1 6
# Corta-Descripción: Aplicaciones comerciales empresariales
# Description: Aplicaciones comerciales de ODOO
### FIN INICIAR INFORMACIÓN
PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/bin
DAEMON=$OE_HOME_EXT/odoo-bin
NAME=$OE_CONFIG
DESC=$OE_CONFIG
# Especifique el nombre de usuario (Predeterminado: odoo).
USER=$OE_USER
# Especifique un archivo de configuración alternativo (Predeterminado: /etc/openerp-server.conf).
CONFIGFILE="/etc/${OE_CONFIG}.conf"
# archivo pid
PIDFILE=/var/run/\${NAME}.pid
# Opciones adicionales que se pasan al Daemon.
DAEMON_OPTS="-c \$CONFIGFILE"
[ -x \$DAEMON ] || exit 0
[ -f \$CONFIGFILE ] || exit 0
checkpid() {
[ -f \$PIDFILE ] || return 1
pid=\`cat \$PIDFILE\`
[ -d /proc/\$pid ] && return 0
return 1
}
case "\${1}" in
start)
echo -n "A partir de \${DESC}: "
start-stop-daemon --start --quiet --pidfile \$PIDFILE \
--chuid \$USER --background --make-pidfile \
--exec \$DAEMON -- \$DAEMON_OPTS
echo "\${NAME}."
;;
stop)
echo -n "Parando \${DESC}: "
start-stop-daemon --stop --quiet --pidfile \$PIDFILE \
--oknodo
echo "\${NAME}."
;;
restart|force-reload)
echo -n "Reiniciando \${DESC}: "
start-stop-daemon --stop --quiet --pidfile \$PIDFILE \
--oknodo
sleep 1
start-stop-daemon --start --quiet --pidfile \$PIDFILE \
--chuid \$USER --background --make-pidfile \
--exec \$DAEMON -- \$DAEMON_OPTS
echo "\${NAME}."
;;
*)
N=/etc/init.d/\$NAME
echo "Uso: \$NAME {start|stop|restart|force-reload}" >&2
exit 1
;;
esac
exit 0
EOF

echo -e "* Archivo de inicio de seguridad"
sudo mv ~/$OE_CONFIG /etc/init.d/$OE_CONFIG
sudo chmod 755 /etc/init.d/$OE_CONFIG
sudo chown root: /etc/init.d/$OE_CONFIG

echo -e "* Iniciar ODOO en el arranque"
sudo update-rc.d $OE_CONFIG defaults

#--------------------------------------------------
# Instale Nginx si es necesario
#--------------------------------------------------
if [ $INSTALL_NGINX = "True" ]; then
  echo -e "\n---- Instalación y configuración de Nginx ----"
  sudo apt install nginx -y
  cat <<EOF > ~/odoo
server {
  listen 80;

  # establecer el nombre de servidor adecuado después del conjunto de dominio
  server_name $WEBSITE_NAME;

  # Agregar encabezados para el modo proxy de Odoo
  proxy_set_header X-Forwarded-Host \$host;
  proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
  proxy_set_header X-Forwarded-Proto \$scheme;
  proxy_set_header X-Real-IP \$remote_addr;
  add_header X-Frame-Options "SAMEORIGIN";
  add_header X-XSS-Protection "1; mode=block";
  proxy_set_header X-Client-IP \$remote_addr;
  proxy_set_header HTTP_X_FORWARDED_HOST \$remote_addr;

  #   archivos de log de odoo
  access_log  /var/log/nginx/$OE_USER-access.log;
  error_log       /var/log/nginx/$OE_USER-error.log;

  #   aumentar el tamaño del búfer del proxy
  proxy_buffers   16  64k;
  proxy_buffer_size   128k;

  proxy_read_timeout 900s;
  proxy_connect_timeout 900s;
  proxy_send_timeout 900s;

  #   forzar tiempos de espera si el backend muere
  proxy_next_upstream error   timeout invalid_header  http_500    http_502
  http_503;

  types {
    text/less less;
    text/scss scss;
  }

  #   habilitar la compresión de datos
  gzip    on;
  gzip_min_length 1100;
  gzip_buffers    4   32k;
  gzip_types  text/css text/less text/plain text/xml application/xml application/json application/javascript application/pdf image/jpeg image/png;
  gzip_vary   on;
  client_header_buffer_size 4k;
  large_client_header_buffers 4 64k;
  client_max_body_size 0;

  location / {
    proxy_pass    http://127.0.0.1:$OE_PORT;
    # by default, do not forward anything
    proxy_redirect off;
  }

  location /longpolling {
    proxy_pass http://127.0.0.1:$LONGPOLLING_PORT;
  }

  location ~* .(js|css|png|jpg|jpeg|gif|ico)$ {
    expires 2d;
    proxy_pass http://127.0.0.1:$OE_PORT;
    add_header Cache-Control "public, no-transform";
  }

  # almacenar en caché algunos datos estáticos en la memoria durante 60 minutos.
  location ~ /[a-zA-Z0-9_-]*/static/ {
    proxy_cache_valid 200 302 60m;
    proxy_cache_valid 404      1m;
    proxy_buffering    on;
    expires 864000;
    proxy_pass    http://127.0.0.1:$OE_PORT;
  }
}
EOF

  sudo mv ~/odoo /etc/nginx/sites-available/$WEBSITE_NAME
  sudo ln -s /etc/nginx/sites-available/$WEBSITE_NAME /etc/nginx/sites-enabled/$WEBSITE_NAME
  sudo rm /etc/nginx/sites-enabled/default
  sudo service nginx reload
  sudo su root -c "printf 'proxy_mode = True\n' >> /etc/${OE_CONFIG}.conf"
  echo "¡Hecho! El servidor Nginx está en funcionamiento. La configuración se puede encontrar en /etc/nginx/sites-available/$WEBSITE_NAME"
else
  echo "Nginx no está instalado debido a la elección del usuario!"
fi

#--------------------------------------------------
# Habilitar ssl con certbot
#--------------------------------------------------

if [ $INSTALL_NGINX = "True" ] && [ $ENABLE_SSL = "True" ] && [ $ADMIN_EMAIL != "info.sofbiz@gmail.com" ]  && [ $WEBSITE_NAME != "_" ];then
  sudo add-apt-repository ppa:certbot/certbot -y && sudo apt-get update -y
  sudo apt-get install python3-certbot-nginx -y
  sudo certbot --nginx -d $WEBSITE_NAME --noninteractive --agree-tos --email $ADMIN_EMAIL --redirect
  sudo service nginx reload
  echo "¡SSL/HTTPS está habilitado!"
else
  echo "¡SSL/HTTPS no está habilitado debido a la elección del usuario o debido a una mala configuración!"
fi

echo -e "* Iniciar el servicio Odoo"
sudo su root -c "/etc/init.d/$OE_CONFIG start"
echo "-----------------------------------------------------------"
echo "¡Hecho! El servidor Odoo está en funcionamiento. Especificaciones:"
echo "Puerto: $OE_PORT"
echo "Servicio al usuario: $OE_USER"
echo "Ubicación del archivo de configuración: /etc/${OE_CONFIG}.conf"
echo "Ubicación del archivo log: /var/log/$OE_USER"
echo "Usuario PostgreSQL: $OE_USER"
echo "Ubicación del código: $OE_USER"
echo "Carpeta de Addons: $OE_USER/$OE_CONFIG/addons/"
echo "Contraseña de Master o Superadmin (database): $OE_SUPERADMIN"
echo "Iniciar el servicio Odoo: sudo service $OE_CONFIG start"
echo "Detener el servicio Odoo: sudo service $OE_CONFIG stop"
echo "Reiniciar el servicio Odoo: sudo service $OE_CONFIG restart"
if [ $INSTALL_NGINX = "True" ]; then
  echo "Archivo de configuración de Nginx: /etc/nginx/sites-available/$WEBSITE_NAME"
fi
echo "-----------------------------------------------------------"