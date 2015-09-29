#!/bin/bash
grupo="/home/dario/sisopgrupo3/grupo03"
# Script del comando IniciaC
# Códigos de error:
# 1 : Fecha del sistema anterior a 2007/09/26
# 2 : Perl no está instalado
# 3 : La versión de Perl es anterior a la 5.0.0

# Exporto $grupo para que todos los otros comandos la usen
export grupo

# Agrego $grupo al $PATH del usuario actual y exporto
# la variable para que los demás comandos puedan usarla.
echo "Agregando el directorio $grupo a PATH..."
PATH=$PATH:"$grupo"
export PATH

# Doy todos los permisos (777) para todos los archivos en $grupo y
# sus subdirectorios (opción -R de chmod).
echo "Otorgando permisos a $grupo..."
chmod -R 777 "$grupo"

# Verifico que la fecha del sistema sea posterior a 2007-09-26
# Para ello, la obtengo como el número aaaammdd, que es el formato
# que mejor se presta a las comparaciones.
echo "Validando la fecha del sistema..."
fecha=$(date +%Y%m%d)
if [ $fecha -lt 20070926 ]; then
    echo "Fecha del sistema anterior a 2007/09/26. Corríjala y pruebe de nuevo."
    exit 1
fi
echo "Fecha OK"

# Verifico si Perl está instalado
echo "Verificando versión de Perl..."
versionperl=$(perl -V:version)
# Si Perl no está instalado, el último comando dará error, ergo $? será no nulo
if [ $# -ne 0 ]
then
    echo "Perl no está instalado. Instale la versión 5 o posterior y pruebe de nuevo."
    exit 2
fi
echo "Versión de Perl instalada: ${versionperl#[a-z]*=}"
# Aunque Perl esté instalado, debo verificar que la versión sea la 5 o posterior.
# Si el comando fue exitoso, devolverá un string de la forma version='5.8.7';
# Comparándolo lexicográficamente con el string constante version=' 5.0.0', se puede
# determinar si la versión de Perl cumple el requisito de ser posterior a la 5.
if [[ "$versionperl" < "version='5.0.0'" ]]
then
    echo "Se requiere la versión de Perl 5 o posterior. Actualice e intente de nuevo."
    exit 3
fi

# Pregunto al usuario hasta obtener una respuesta (sí o no).
AUTO="a"
until [ $AUTO == "s" -o $AUTO == "S" -o $AUTO == "n" -o $AUTO == "N" ]
do
    echo "¿Desea efectuar una corrida manual? s/n ENTER"
    read AUTO
done

# Le doy valor a AUTO según la respuesta del usuario
if [ $AUTO == "s" -o $AUTO == "S" ]
then
    AUTO="NO"
else
    AUTO="SI"
fi

echo "Verificando si RecibeC está corriendo..."
corre=$(ps --no-headers -C RecibeC.sh | wc -l)
if [ "$corre" -gt "0" ]
then
    # Está corriendo; muestro hace cuánto.
    echo "RecibeC está corriendo hace ..."
    ps --no-headers -C RecibeC.sh -o  %t
    echo "Formato del tiempo: [dd]:[hh]:mm:ss"
else
    # No está corriendo
    if [ $AUTO == "SI" ]
    then
        # Lo mando a correr en el background
	echo "RecibeC no está corriendo. Lanzando RecibeC..."
        $grupo/RecibeC.sh $AUTO &
        echo "El process id de RecibeC es:"
        ps aux | grep -m 1 "RecibeC" | sed "s/^[^ ]*[ ]*\([0-9]*\).*$/\1/g"
    else
        echo "RecibeC no está corriendo"
    fi
fi

exit 0

