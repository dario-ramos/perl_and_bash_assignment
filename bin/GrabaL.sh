#!/bin/bash
# Loguer.
#Graba el mensaje recibido, en el archivo de log correspondiente al comando que lo invoca.

if [ $# -ne 2 ]
then
   echo 'ERROR: parametros incorrectos'
   echo 'Uso: GrabaL <comando> <mensaje de log>'
   exit 1
fi
   
cat <<Fin >>"$grupo/log/$1.log"
---------------------------------------------
Mensaje: $2
Fecha: `date '+%d/%m/%Y %H:%M:%S'`
Usuario: $USER
Fin
