#!/bin/bash
grupo="/home/dario/sisopgrupo3/grupo03"
export grupo
clear
IFS=' '
# si $grupo/recibidos/ NO ESTA VACIO comenzar ejecucion
APROCESAR=`ls "$grupo"/recibidos/ -1 -X | grep -o -e '[0-9]\{4\}$'`

if [  -z $APROCESAR ]
then
	exit
fi

CANTREC=`echo $APROCESAR | wc -l` 

#Calculo corrida:
IFS='
 '
declare -a ARCHIVOS

CANT=`find "$grupo"/recibidos/procesados -type f -name '[0-9]*' | wc -l`
if [ $CANT -eq 0 ]
then
	CORRIDA=1000
else
	CORRIDA=0
	for filename in `ls "$grupo"/recibidos/procesados -1 -X | grep -o -e '[0-9]\{4\}$'`
	do
		if [  "$CORRIDA" -lt "$filename" ]; then
			CORRIDA=$filename
		fi
			
	done
	CORRIDA=$(echo "$CORRIDA +1 "|bc) 
	#tratar de recuperar ultima posicion
fi
#Grabo en el Log que comienza el proceso:
LOG=""$grupo"/log/log.txt"
. "$grupo"/bin/GrabaL.sh ValidCo "*******INICIO DE Corrida "$CORRIDA". Archivos a procesar "$CANTREC" **********"
#date >> $LOG
#echo $USER >> $LOG

IFS='
'
#Si no está vacío, tomo cada archivo y lo proceso:
PWD_TEMP=$PWD
cd "$grupo"/recibidos
ARCHIVOS=`ls -1 *.[0-9][0-9][0-9][0-9][0-9][0-9]`

for filename in $ARCHIVOS
do
	#grabar en log:
	. "$grupo"/bin/GrabaL.sh ValidCo "Inicio Proceso de Archivo $filename"
	
	rechazados=`expr 0`
	aprobados=`expr 0`
	CONTRIBUYENTE=`echo $filename | grep -o -e '^[[:digit:]]\{11\}'`
	PERIODO=`echo $filename | grep -o -e '[[:digit:]]\{6\}$'`
	MES=`echo $PERIODO | grep -o -e '[[:digit:]]\{2\}$'`
	ANIO=`echo $PERIODO | grep -o -e '^[[:digit:]]\{4\}'`
	for linea in `cat $filename`
	do
		ERROR=0
		REG=`echo $linea | grep -e '^[[:digit:]]\{11\},[[:alnum:] ]\{1,\},[FCD]\{1\},[[:digit:]]\{5,\},[[:digit:]-]\{10\},[[:digit:]]\{1,\}[\.]\?[[:digit:]]\{0,3\},[[:digit:]]\{1,\}[\.]\?[[:digit:]]\{0,2\},[[:digit:]]\{1,\}[\.]\?[[:digit:]]\{0,3\},[[:digit:]]\{0,\}[\.]\?[[:digit:]]\{0,3\},[[:digit:]]\{0,\}[\.]\?[[:digit:]]\{0,2\},[[:digit:]]\{0,\}[\.]\?[[:digit:]]\{0,3\},[[:digit:]]\{0,\}[\.]\?[[:digit:]]\{0,3\},[[:digit:]]\{0,\}[\.]\?[[:digit:]]\{0,2\},[[:digit:]]\{0,\}[\.]\?[[:digit:]]\{0,3\},[[:digit:]]\{0,\}[\.]\?[[:digit:]]\{0,3\},[[:digit:]]\{1,\}[\.]\?[[:digit:]]\{0,3\}'`			
				
		if [ -z $REG  ]	; then
			#echo "Error de formato o datos"
			ERROR=1
		fi	

		#Separo los ,, para que entren en el vecto al usar awk
		TRANS=`echo "$REG" | grep -e ',,' | wc -l`

		while [ "$TRANS" != 0 ]  ; do
			REG=`echo "$REG" | sed s/",,"/", ,"/g`
			TRANS=`echo "$REG" | grep -e ',,' | wc -l`
		done		
	
		SEP=$(echo $REG | awk 'BEGIN{FS = ","}{print $1 "\n" $2 "\n" $3 "\n" $4 "\n" $5 "\n" $6 "\n" $7 "\n" $8 "\n" $9 "\n" $10 "\n" $11 "\n" $12 "\n" $13 "\n" $14 "\n" $15 "\n" $16}')
		VECTOR=($SEP)
		if [ ${#VECTOR[@]} = 0 ]			
		then
			#echo "Erroneo por validacion"
			ERROR=1
		fi
		TOTAL=0
		
		for ((i=0; i< ${#VECTOR[@]}; i++ ))
		do	
		 

			case "$i" in
			#Valido fecha del comprobante:		
			4) 				
				MES_C=`echo "${VECTOR[$i]}" | grep -o -e '[-][[:digit:]]\{2\}[-]' | tr -d '-'`
				#echo $MES_C
				ANIO_C=`echo "${VECTOR[$i]}" | grep -o -e '[[:digit:]]\{4\}$'`
				#echo $ANIO_C
					
				if [ "$ANIO_C" -gt "$ANIO"  ] ; then
					#echo "Anio Mayor Erroneo"
					ERROR=1
				 	break
				else	if [ "$ANIO_C" -eq "$ANIO" ] && [ "$MES_C" -gt "$MES" ] ; then

						#echo "Error por mes mayor"
						ERROR=1
						break
					fi
				fi
			;;
			#Valido 7.25 <= Alìcuota <=27 
			6 | 9 | 12 )
			 if [ $(echo "${VECTOR[$i]} > 7.25"|bc) -eq 0 ] ||  [ $(echo "${VECTOR[$i]} < 27"|bc) -eq 0 ]  ; then
					#echo "Error por alicuota"
					ERROR=1
					break
			 fi
			;;
			5 | 7 | 8 | 10 | 11 | 13 | 14 ) if [ "${VECTOR[$i]}" != " " ] ; then
								TOTAL=` echo "$TOTAL + ${VECTOR[$i]}"| bc `
							fi
			;;
			15)	if [ "${VECTOR[$i]}" != " " ] ; then				
					DIF=`echo "$TOTAL - ${VECTOR[$i]}"| bc`
					
					ABS=`echo "$DIF" | awk ' { if($DIF>=0) { print $DIF} else {print $DIF*-1 }}'`
					
					if [ $(echo "$ABS > 0.03"|bc) -eq 1 ]  ; then
						#echo "Error por diferencia"	
						ERROR=1
						break
			 		fi
				else
					#echo "Error por falta de datos"
					ERROR=1
					break
				fi
			;;  	
			esac
		done
	#Si el registro està Ok, genero CAE
	DESTINO=""$grupo"/recibidos/procesados/$filename"

	if [ $ERROR -eq 1 ]; then
		echo "$linea,RECHAZADO" >> $DESTINO
		rechazados=`expr $rechazados + 1`
		continue
	fi

	CPBT=""$grupo"/tablas/cpbt.txt"

	if [ -f $CPBT ] ; then
		LIST_CPBT=`cat $CPBT | grep -e $CONTRIBUYENTE,${VECTOR[2]},`
		
		if [ -z $LIST_CPBT  ]; then
			echo "$CONTRIBUYENTE,${VECTOR[2]},0001,0001" >> $CPBT
			CAE=00001/$CORRIDA
		else
			SEP=$(echo $LIST_CPBT | awk 'BEGIN{FS = ","}{print $1 "\n" $2 "\n" $3 "\n" $4}')
			VCPBT=($SEP)
					
			SECUENCIA=$(echo "${VCPBT[3]} + 00001"|bc) 
			if [ $(echo "$SECUENCIA > 99999"|bc) -eq 1 ] ;then
				SECUENCIA=00001
			fi
			CAE=`echo $SECUENCIA'/'$CORRIDA`
					
			#Guardo la Ultima Secuencia:
			CPBT_TEMP=""$grupo"/tablas/cpbt.temp"
			LIST_CPBT=`cat $CPBT | grep -v -e $CONTRIBUYENTE,${VECTOR[2]}, > $CPBT_TEMP`
					
			echo "$CONTRIBUYENTE,${VECTOR[2]},00001,$SECUENCIA" >> $CPBT_TEMP
			rm -f $CPBT
			mv $CPBT_TEMP $CPBT
		fi
	else
		echo "$CONTRIBUYENTE,${VECTOR[2]},00001,00001" >> $CPBT
		CAE=00001/$CORRIDA
 	fi
	#Agrego CAE al registro

	#Copio el registro + CAE al archivo $grupo03/recibidos/procesados/<nombre archivo orig>.<nro corrida>	
	#Contabilizar registros procesados ok +=1
		echo "$linea,$CAE" >> $DESTINO

	#Armo el registro para IvaC
	IVAC="$grupo"/IvaC/$PERIODO
	TOTAL_GRAVADO=$( echo "${VECTOR[5]} + ${VECTOR[8]} + ${VECTOR[11]}" | bc)
	TOTAL_IMPUESTO=$( echo  "${VECTOR[7]} + ${VECTOR[10]} + ${VECTOR[13]}" | bc)

echo "$CONTRIBUYENTE,$CAE,${VECTOR[2]},${VECTOR[4]},${VECTOR[15]},${VECTOR[14]},$TOTAL_GRAVADO,$TOTAL_IMPUESTO" >> $IVAC

	aprobados=`expr $aprobados + 1`  
		
	#fin de registros de un archivo determinado	
	done
	
	
	. "$grupo"/bin/GrabaL.sh ValidCo "FIN del Proceso de Archivo $filename"
	. "$grupo"/bin/GrabaL.sh ValidCo "Cantidad Procesados Ok: $aprobados.  Registros Rechazados: $rechazados" 
	
#fin del archivo
done
. "$grupo"/bin/GrabaL.sh ValidCo "*******FIN de Corrida $CORRIDA ********"


cd $PWD_TEMP

