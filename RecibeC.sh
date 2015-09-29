#!/bin/bash
grupo="/home/dario/sisopgrupo3/grupo03"

#Funcion que mueve el archivo recibido por parametro a recibidos si este no existe, o a norecibidos
#si ya existe en recibidos.
function moverANorecibidos () {
arch=$1
archivos=`ls -m "$grupo/norecibidos"`
echo $archivos | sed "s/, /;;/g" | sed "s/^.*$/;&;/" >> archivos.txt

#Con esto obtengo los archivos que tienen el mismo nombre
resultado=`grep -o ";$arch[0-9\.]*;" archivos.txt | sed "s/;//g"`
rm archivos.txt

for archivo in $resultado
do
  existeSecuencia=`echo $archivo | grep "$arch\..*"`
  #Me fijo si tiene punto, es decir si ya hay un arch con nro de secuencia
  if [ -z $existeSecuencia ]
  then
      #me fijo que existe el nombre del archivo y que no haya confundido con otro (ej: 123.123 con 123.123333)
      if [ $archivo == $arch ]
      then
	ultimoNro=000	
      fi
  else
      nro=`echo $archivo | sed "s/[0-9]*\.[0-9]*\.\([0-9]*\).*/\1/"`
      #ya existe un archivo con nro de secuencia.
      if [ $nro -gt $ultimoNro  ]
      then
	ultimoNro=$nro
      fi
  fi
done
#Si ultimo nro es vacio quiere decir que el archivo no esta en el dir.
if [ -z $ultimoNro ]
then
  #como el archivo no existe, lo muevo sin renombrar.
  mv "$grupo/arribos/$arch" "$grupo/norecibidos/$arch"
  "$grupo"/bin/GrabaL.sh RecibeC "Archivo Duplicado: $arch"
else
  nroSec=$[$ultimoNro+1]
  #muevo y renombro con *.nroSec
  mv "$grupo/arribos/$arch" "$grupo/norecibidos/$arch.$nroSec"
  "$grupo"/bin/GrabaL.sh RecibeC "Archivo Duplicado: $arch.$nroSec"
fi
}

#Recibir los datos de los clientes
RECIBIR=""

echo "RecibeC recibiendo..." #TODO

if [ "$1" ]
then
	AUTO=$1
else
	AUTO="NO"
fi

if [ "-$RECIBIR-" != '--' ]   #verifica si el programa se esta ejecutando
then
 echo "El programa ya se estaba ejecutando"
 exit 1
fi

echo "Valor de AUTO: $AUTO" #TODO

RECIBIR=ON

recflag="NO"
while [ 1 ]; do

 arch=`ls "$grupo/arribos" -all | egrep "[0-9]{11}.[0-9]{6}$" | head -n1`
 if [ "-$arch-" != "--" ]
 then
   pos=`echo ${#arch} - 18`
   arch=`echo ${arch:$pos:18}`
   cuit=${arch:0:11}
   periodo=${arch:12:6}

   mesp=${periodo:4:2}
   aniop=${periodo:0:4}


   mesact=`date +%m`
   anioact=`date +%Y`


   if [ $mesp = '12' ]
   then
     mesp='12'
   fi
   if [ $mesp = '01' ]
   then
     mesp='13'
   fi
   if [ $mesp = '02' ]
   then
     mesp='14'
   fi
   if [ $mesact = '12' ]
   then
     $mesact='12'
   fi
   if [ $mesact = '01' ]
   then
     $mesact='13'
   fi
   if [ $mesact = '02' ]
   then
     $mesact='14'
   fi
   fecha="NOK"
   rest=`expr $anioact + 100 - $aniop`
   if [ "$rest" -gt "98" ]
   then
     if [ "102" -gt "$rest" ]
       then
         fecha="OK"
     fi
   fi
   mesact=`expr $mesact + 20`
   mesp=`expr $mesp + 20`
   if [ "$fecha" = "OK" ]
     then
       fecha="NOK"
       mesact=`expr $mesact - 3`
       if [ "$mesp" -gt "$mesact" ]
       then
         mesact=`expr $mesact + 5`
         if [ "$mesact" -gt "$mesp" ]
         then
         fecha="OK"
         fi
      fi
     fi

   #Validar cuit
   ctflag="NOK"
   if [ "$fecha" = "OK" ]
   then
     anioct=`cat "$grupo/tablas/ctbyt.txt" | grep "$cuit" | head -n1 | cut -d"," -f3 | cut -d"-" -f1`
     mesct=`cat "$grupo/tablas/ctbyt.txt" | grep "$cuit" | head -n1 | cut -d"," -f3 | cut -d"-" -f2`
     if [ "-$anioct-" = "--" ]
     then
       ctflag="NOESTA"
     fi
     if [ "-$mesct-" = "--" ]
     then
       ctflag="NOESTA"
     fi
     if [ "$ctflag" = "NOK" ]
     then
       mesp=${periodo:4:2}
       aniop=${periodo:0:4}
       if [ "$aniop" -ge "$anioct" ]
       then
         if [ "$mesp" -ge "$mesct" ]
         then
           ctflag="OK"
         fi
       fi
     fi
   fi
   #fin validar cuit
   if [ "$ctflag" = "NOK" ] # mal fecha periodo contribuyente archivo
   then
     
     . "$grupo"/bin/GrabaL.sh RecibeC "Periodo no habilitado: $arch"
     if [ -e "$grupo/norecibidos/$arch" ]
         then
           rm "$grupo/norecibidos/$arch"
         else
           mv "$grupo/arribos/$arch" "$grupo/norecibidos"
         fi
   else
   if [ "$ctflag" = "NOESTA" ]
   then
     if [ -e "$grupo/norecibidos/$arch" ]
         then
           "$grupo"/bin/Nro de CUIT InexistenteGrabaL.sh RecibeC "Nro de CUIT Inexistente: $arch"
           rm "$grupo/norecibidos/$arch"
         else
           mv "$grupo/arribos/$arch" "$grupo/norecibidos"
         fi
   else
     if [ "$fecha" = "NOK" ] # mal fecha archivo
       then
         . "$grupo"/bin/GrabaL.sh RecibeC "Periodo Fuera de Rango: $arch"
         if [ -e "$grupo/norecibidos/$arch" ]
         then
           rm "$grupo/norecibidos/$arch"
         else
           mv "$grupo/arribos/$arch" "$grupo/norecibidos"
         fi
       else
	  #Pregunto si el archivo ya existe en recibidos.
	  if [ -e "$grupo/recibidos/$arch" ]
	  then
	    #el archivo ya existe.
	    moverANorecibidos $arch
	  else
	    #el archivo no existe en recibidos
	    mv "$grupo/arribos/$arch" "$grupo/recibidos/$arch"
	    recflag="SI"
	    . "$grupo"/bin/GrabaL.sh RecibeC "Archivo Recibido: $arch"
	  fi
       fi
     fi
   fi
 else # mal sintaxis archivo

   arch=`ls "$grupo/arribos" -all | grep "^[-]1*" | head -n1 | sed "s/^[^ ]*[ ]*[^ ]*[ ]*[^ ]*[ ]*[^ ]*[ ]*[^ ]*[ ]*[^ ]*[ ]*[^ ]*[ ]*\([^ ]*\).*/\1/"`
   if [ "-$arch-" != "--" ]
   then
     if [ -e "$grupo/norecibidos/$arch" ]
      then
        . "$grupo"/bin/GrabaL.sh RecibeC "Nombre de archivo Incorrecto: $arch"
        rm "$grupo/norecibidos/$arch"
      else
        . "$grupo"/bin/GrabaL.sh RecibeC "Nombre de archivo Incorrecto: $arch"
        mv "$grupo/arribos/$arch" "$grupo/norecibidos"
     fi
   else
     if [ "$recflag" = "SI" ]
     then
       if [ "$AUTO" = "SI" ]
       then
         corre=$(ps --no-headers -C ValidCo.sh | wc -l) 
         if [ "$corre" -gt "0" ] 
         then 
           corre=0
         else
	   echo "Voy a llamar a ValidCo" #TODO
           "$grupo"/ValidCo.sh &
           corre=$(ps --no-headers -C ValidCo.sh | wc -l) 
           if [ "$corre" -gt "0" ] 
           then 
             echo "El process id de ValidCo es:" 
             ps aux | grep -m 1 "ValidCo" | sed "s/^[^ ]*[ ]*\([0-9]*\).*$/\1/g"
           else
             echo "Error al intentar inciar ValidCo"
           fi
         fi
       fi
       recflag="NO" 
     fi
     sleep 5
   fi
 fi

done

RECIBIR=OFF

