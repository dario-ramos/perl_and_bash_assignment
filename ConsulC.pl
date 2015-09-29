#!/usr/bin/perl -w
$grupo = "/home/dario/sisopgrupo3/grupo03";

#Constantes de los campos de los registros de los archivos ivaC
use constant CONTRIBUYENTE => 0;
use constant TIPO_COMPROBANTE => 2;
use constant FECHA => 3;
use constant IMPORTE_NETO_GRAVADO => 6;
use constant IMPUESTO_LIQUIDADO =>7;

use Time::gmtime;
use Date::Parse;
use Switch;


open(ARCHIVOS,"ls $grupo/ivaC/ -1 |");
@filenames = <ARCHIVOS>;
close(ARCHIVOS);

# Proceso cada archivo en la lista de archivos
foreach $filename (@filenames){
	# Elimino el \n al final del nombre del archivo
	chomp $filename;

	open(ARCH,$grupo."/ivaC/".$filename);
	@lineasArch = <ARCH>;
	push @lineas,@lineasArch;
	close(ARCH);
}
$clave = "";
$paramAno2 = "";
$paramMes2 = "";

$key=0;
$opGrav=0;
$impLiq=0;

@time = localtime();
$dia = $time[3];
$mes = $time[4]+1;
$ano = $time[5]+1900;

$nombreListado = "contribuyentes declarantes";
$guion = "";

format STDOUT_TOP =
Listado de @<<<<<<<<<<<<<<<<<<<<<<<<<  @#/@#/@###       Periodo @>>> @> @ @>>> @>
$nombreListado,                        $dia,$mes,$ano,          $paramAno,$paramMes,$guion,$paramAno2,$paramMes2
---------------------------------------------------------------------------------
.

format STDOUT =
@>>>>>>>>>>>>>     @#########.###     @########.###
$clave,            $opGrav,           $impLiq 
.

format ARCH_TOP =
Listado de @<<<<<<<<<<<<<<<<<<<<<<<<<  @#/@#/@###       Periodo @>>> @> @ @>>> @>
$nombreListado,                        $dia,$mes,$ano,          $paramAno,$paramMes,$guion,$paramAno2,$paramMes2
---------------------------------------------------------------------------------
.

format ARCH =
@>>>>>>>>>>>>>     @#########.###     @########.###
$clave,            $opGrav,           $impLiq 
.

# Verifico los parametros
@params = @ARGV;
if ($params[0] eq "-w"){
	$salida = ARCH;
	#delete $params[0];
	@params = @params[1..$#params];
} else {
	$salida = STDOUT;
}

sub validarAno{
	$valid=$_[0]=~/^\d{4,4}$/;
	if (!$valid){
		print ("Formato de fecha incorrecto\n");
		exit 1;
	}
}

sub validarMes{
	$valid=$_[0]=~/^([0][0-9]|[1][0-2])$/;
	if (!$valid){
		print ("Formato de periodo incorrecto\n");
		exit 1;
	}
}

switch ($#params){
	case 1 {
		$paramAno = $params[0];
		$paramMes = $params[1];
		validarAno($paramAno);
		validarMes($paramMes);
		&imprimirListadoContribuyentesDeclarantes();
	}
	case 3 {
		$paramAno = $params[0];
		$paramMes = $params[1];
		validarAno($paramAno);
		validarMes($paramMes);
		$paramAno2 = $params[2];
		$paramMes2 = $params[3];
		validarAno($paramAno2);
		validarMes($paramMes2);
		if ($paramAno.$paramMes gt $paramAno2.$paramMes2) {
			print("La fecha de periodo inicial debe ser menor a la final\n");
			exit 1;
		}
		$guion="-";
		$nombreListado = "compras declaradas";
		&imprimirListadoComprasDeclaradas();
	}
	else {
		print("Cantidad de parametros incorrectos\n");
		exit 1;
	} 
}




if (!open(ARCH,"> consultas/consulta")) {
	print ("No se pudo abrir el archivo de salida\n");
	exit 1;
}
sub imprimirListadoContribuyentesDeclarantes(){
	foreach $linea (@lineas){
		if (length($linea)>0){
			@reg = split(/,/,$linea);
			@fecha = split(/-/,$reg[FECHA]);
			$year = $fecha[0];
			$month = $fecha[1];
			if ($paramAno.$paramMes eq $year.$month) {
				# Si el Tipo de Comprobante es Factura (F) o Debito (D) se resta
				if (($reg[TIPO_COMPROBANTE] eq "F") || ($reg[TIPO_COMPROBANTE] eq "D")){
					$operacionesGravadas{$reg[CONTRIBUYENTE]}-= $reg[IMPORTE_NETO_GRAVADO];
					$impuestoLiquidado{$reg[CONTRIBUYENTE]}-= $reg[IMPUESTO_LIQUIDADO];
				} else {
					# En otro caso, se suma
					$operacionesGravadas{$reg[CONTRIBUYENTE]}+= $reg[IMPORTE_NETO_GRAVADO];
					$impuestoLiquidado{$reg[CONTRIBUYENTE]}+= $reg[IMPUESTO_LIQUIDADO];
				}
			}
		}
	}
}

sub imprimirListadoComprasDeclaradas(){
	foreach $linea (@lineas){
		if (length($linea)>0){
			# Creo un array con los campos de esta linea
			@reg = split(/,/,$linea);
			# La fecha viene en formato aaaa-mm-dd
			@fecha = split(/-/,$reg[FECHA]);
			$year = $fecha[0];
			$month = $fecha[1];
			# El mes y ano de este registro debe estar comprendido entre los argumentos pasados al comando
			# para ser procesado
			if (($paramAno.$paramMes le $year.$month) && ($paramAno2.$paramMes2 ge $year.$month)) {
				$clave = $year.$month;
				# Si el Tipo de Comprobante es Factura (F) o Debito (D) se resta
				if (($reg[TIPO_COMPROBANTE] eq "F") || ($reg[TIPO_COMPROBANTE] eq "D")){
					$operacionesGravadas{$clave}-= $reg[IMPORTE_NETO_GRAVADO];
					$impuestoLiquidado{$clave}-= $reg[IMPUESTO_LIQUIDADO];
				} else {
				# En otro caso, se suma
					$operacionesGravadas{$clave}+= $reg[IMPORTE_NETO_GRAVADO];
					$impuestoLiquidado{$clave}+= $reg[IMPUESTO_LIQUIDADO];
				}
			}
		}
	}
}

$cantOperaciones = 0;

foreach $key (sort(keys %impuestoLiquidado)){
	$cantOperaciones++;
	$opGrav = $operacionesGravadas{$key};
	$impLiq = $impuestoLiquidado{$key};
	$montoOperacionesGravadas+=$opGrav;
	$montoImpuestoLiquidado+=$impLiq;
	$clave = $key;
	write $salida;
}

if ($cantOperaciones > 0){
	$clave = "";
	$opGrav = $montoOperacionesGravadas/$cantOperaciones;
	$impLiq = $montoImpuestoLiquidado/$cantOperaciones; 
}
write $salida;
