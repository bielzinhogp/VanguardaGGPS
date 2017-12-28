#!/bin/bash

# ----------------------------------------------------------------------------
#Autor: Gabriel Guimaraes Pires da Silva
#Versao: 1.0
#Data: 20/10/2017
# ----------------------------------------------------------------------------

menu ()
{
	while true $x != "teste"
	do
	clear
	echo "================================================"
	echo "Automacao destravar PDV"
	echo "Em casos de duvidas contactar por e-mail: gabriel.pires@linx.com.br"
	echo ""
	echo "1)Resolver carga de Base"
	echo""
	echo "2)Resolver arquivos de parametros corrompidos"
	echo""
	echo "3)Recuperar CMOS".
	echo""
	echo "0)Sair do programa"
	echo ""
	echo "================================================"

	echo "Digite a opcao desejada:"
	read x
	echo "Opcao informada ($x)"
	echo "================================================"

	case "$x" in


    1)
	
	echo "Insira o nome do pdv ou o IP (Ex: ecf1 ou 192.168.1.1): "
	read pdv
	echo "================================================"
	echo "Gerando par de chave publica/privada"
	echo "Sera necessario pressionar enter para continuar"
	echo "Caso esse PDV nunca tenha sido acessado ira solicitar sua senha apos gerar o par de chaves"
	echo "================================================"
	ssh-keygen 
	ssh-copy-id -i ~/.ssh/id_rsa.pub root@$pdv
	base=`ls -t Comercial*  | head -n 1`
    scp $base root@$pdv:/p2k/sp/database/main
	echo "Arquivo transferido"
	ssh root@$pdv << EOF
	  cd /p2k/sp/database/main/
	  unzip -o $base
	  echo Arquivo descompactado
	  rm -rf $base
	  cd ~
	  echo "Matando aplicacao java"
	  killall -9 java
	  killall -9 java
	  #. /p2k/bin/criapermissaoPDV.sh
	  #. /p2k/bin/setClassPathComponente.sh
	  #. /p2k/bin/configPDV.sh
	  echo "Iniciando PDV"
	  init 3
	  sleep 5
	  init 5

EOF
	sleep 3
			  

	echo "================================================"
	break
	;;
	
    2)
	
    echo "Insira o nome do pdv ou o IP do PDV origem, que se encontra online para copiar os arquivos corrompidos (Ex: ecf1 ou 192.168.1.1): "
	read pdvOrigem
	echo "Insira o o nome do pdv ou o IP do PDV destino, no qual deseja enviar os arquivos (Ex: ecf1 ou 192.168.1.1): "
	read pdvDestino
	echo "================================================"
	echo "Gerando par de chave publica/privada entre servidor e PDV"
	echo "Sera necessario pressionar enter para continuar"
	echo "Caso esse PDV nunca tenha sido acessado ira solicitar sua senha apos gerar o par de chaves"
	echo "================================================"
	ssh-keygen 
	ssh-copy-id -i ~/.ssh/id_rsa.pub root@$pdvOrigem
	ssh-copy-id -i ~/.ssh/id_rsa.pub root@$pdvDestino
	scp root@$pdvOrigem:/p2k/bin/\{parametrosGerais.properties,parametrosGeraisSeguranca.properties,parametrosGeraisPerifericos.properties,parametrosGeraisP2K.properties,parametrosGeraisPDV.properties\} .
	echo "Arquivo parametros copiado"
	ssh root@$pdvDestino 'grep ^PARAM_NFCE_AUTORIZADOR /p2k/bin/parametrosGeraisPDV.properties > temp_param'
	scp root@$pdvDestino:/root/temp_param .
	VALOR_ATUAL_NFCE=`cat temp_param`
	
	if [ -z "$VALOR_ATUAL_NFCE" ];
	then
		echo "parametro nao encontrado, seguir procedimento padrao"
		scp parametrosGerais.properties parametrosGeraisSeguranca.properties parametrosGeraisPerifericos.properties parametrosGeraisP2K.properties parametrosGeraisPDV.properties root@$pdvDestino:/p2k/bin/
		echo "Arquivo parametros enviado para o PDV destino"
		ssh root@$pdvDestino << EOF
		echo "Matando aplicacao java"
		killall -9 java
		killall -9 java
		. /p2k/bin/criapermissaoPDV.sh
		. /p2k/bin/setClassPathComponente.sh
		. /p2k/bin/configPDV.sh
		echo "Iniciando PDV"
		init 3
		sleep 5
		init 5
		rm -rf temp_param
EOF
	else
		echo "parametro encontrado"
		sed -i 's/^ VALOR_ATUAL_NFCE =.*/$VALOR_ATUAL_NFCE /' parametrosGeraisPDV.properties
		scp parametrosGerais.properties parametrosGeraisSeguranca.properties parametrosGeraisPerifericos.properties parametrosGeraisP2K.properties parametrosGeraisPDV.properties root@$pdvDestino:/p2k/bin/
		echo "Arquivo parametros enviado para o PDV destino"
		ssh root@$pdvDestino << EOF
		echo "Matando aplicacao java"
		killall -9 java
		killall -9 java
		. /p2k/bin/criapermissaoPDV.sh
		. /p2k/bin/setClassPathComponente.sh
		. /p2k/bin/configPDV.sh
		echo "Iniciando PDV"
		init 3
		sleep 5
		init 5
		rm -rf temp_param
EOF
	fi
	
    sleep 3
	echo "================================================"
	
	break
	
	;;
	
	3)
	echo "Insira o numero da loja: "
	read loja
	numeroLoja=$(echo $loja | sed 's/^0*//')
	echo "Insira o nome do pdv ou o IP (Ex: ecf1 ou 192.168.1.1): "
	read pdv
	echo "Escolha uma opcao de estado: "
	echo "<0> Restaura a CMOS, deixando o PDV em disponivel"
	echo "<1> Restaura a CMOS, deixando o PDV em Venda"
	echo "<2> Restaura a CMOS, deixando o PDV em Recebimento"
	echo "<3> Restaura a CMOS, deixando o PDV em Fechado Parcial"
	echo "<4> Restaura a CMOS, deixando o PDV em Fechado"
	read estado
	chave=$(geraChaveFinal `date +"%Oe%m%y"` $numeroLoja)
	ssh root@$pdv << EOF
	killall -9 java
	killall -9 java
	cd /p2k/bin
	. recuperaCMOS.sh $chave $estado
	reboot
EOF
	echo "================================================"
	break
	;;
	
     0)
	 echo "saindo..."
	 sleep 2
	 break
	 clear		 
	 echo "================================================"
		
	;;

	*)
    echo "Opcaoo invalida!"
	sleep 3
	
esac
done

}
menu
rm -rf parametros*
rm -rf temp_param
rm -rf teste.sh

somaDigitos ()
{
    soma=0
    numero=$1
    while (( $numero > 0 ))
    do
        soma=$(($soma + ($numero%10)))
        numero=$(($numero/10))
    done
    echo $soma
}

geraChaveFinal ()
{
    num1=$1
    num2=$2
    #echo "num1 = $1"  
    #echo "num2 = $2" 
    soma1=$((num1 + num2 + 1))
    #echo "soma1 = $soma1"
    totalDia=$(somaDigitos $num1)
    #echo "totalDia = $totalDia"
    totalLoja=$(somaDigitos $num2)
    #echo "totalLoja = $totalLoja"
    soma2=$((totalDia + totalLoja +1))
    #echo "soma2 = $soma2"
    soma3=$((soma1 * soma2 * 123))
    echo $soma3 | tail -c 7
}

