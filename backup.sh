#!/bin/bash

#Create by Marcelo Valvassori Bittencourt
#v1.0 - 14/10/2020 | SGO - Seção de Gerenciamento das Operações | script de backup por pasta
#v1.1 - 23/11/2020 | Adição de remoção de backup antigos do ACL após execução com sucesso de backup do mesmo.
#v1.2 - 17/03/2021 | Correções diversas e logs de erro em arquivo
#v1.3 - 13/07/2021 | Adição de testes logicos para poder rodar script e cancela-lo sempre que necessário sem perdas e sem que o mesmo realize backup de arquivos que já foram realizados

#Melhorias:
# - Script como servico no linux https://www.vivaolinux.com.br/topico/Shell-Script/Criacao-de-servicos

datainicial=`date +%s`


_origem=/var/www        #origem dos backups
_destino=/chucabum      #destino do backup

_tar=$(which tar)
_id=$(date +"%Y-%m-%d")

_retencao=1             #valor em dias / remover arquivos com mais de X dias
_errlog=/tmp/err-bkp_${_id}.log

_debug=true

instalado=$(dpkg --get-selections | grep -c tar)
if [ "$instalado" -ne "0" ]; then

	echo "Inicio do backup de FTP"
	ftp_backupeado=$(find ${_destino}/proftpd-*.tar.gz -mtime 0 2> $_errlog | wc -l)
	if [ $ftp_backupeado -eq 0 ]
	then
		ftp_datainicial=`date +%s`
        #backup das configurações de ftp
        pftp_out=$($_tar -zcf ${_destino}/proftpd-${_id}.tar.gz /etc/proftpd/* 2>&$pftp_error)
		[ -n $_debug ] && echo "Saida: \n $pftp_out"
        if [ -z $pftp_out ]
        then
			echo "Backup do proFTPd executado com sucesso."			
			pftp_out_rm=$(find ${_destino}/proftpd-*.tar.gz -mtime +${_retencao} -exec rm {} \; 2>&$pftp_rm_error)
			[ -n $_debug ] && echo "Saida: \n $pftp_out_rm"
			if [ -z $pftp_rm_error ]
			then
				echo "Backup com mais de um dia do proFTPd removido com sucesso."
			else
				_errlog+=${pftp_rm_error}
				echo "Não foi possível remover backups antigos do proFTPd. Verifique arquivo de log $_errlog"
				[ -n $_debug ] && echo "Erro: $pftp_rm_error"
			fi			
        else
			_errlog+=${pftp_error}
			echo "Não foi possível gerar backup das configurações do proFTPd. Verifique arquivo de log $_errlog"
			[ -n $_debug ] && echo "Erro: $pftp_error"
        fi
		
		ftp_datafinal=`date +%s`
        ftp_soma=`expr $ftp_datafinal - $ftp_datainicial`
        ftp_resultado=`expr 10800 + $ftp_soma`
        ftp_tempo=`date -d @$ftp_resultado +%H:%M:%S`
        echo "Tempo de execução do backup das configurações de FTP: $ftp_tempo"
        echo ""
	else
		echo "Backup do proFTPd já realizado."
	fi
	echo "Fim da execução do script de backup FTP"
    
	# _pid=$(pidof tar) && kill -9 ${_pid}

	#backup acl | para restaurar: setfacl --restore=acl_backup-{data}.acl
        
	echo "Inicio do backup ACL"
	acl_backupeado=$(find ${_destino}/acl_backup-*.acl -mtime 0 2>$_errlog | wc -l)
	if [ $acl_backupeado -eq 0 ]
	then
		acl_datainicial=`date +%s`
		facl_out=$(getfacl -R ${_origem} > ${_destino}/acl_backup-${_id}.acl 2>&$facl_error)
		[ -n $_debug ] && echo "Saida: \n $facl_out"
		if [ -z $facl_out ]
		then
			echo "Backup do ACL executado com sucesso."
			
			facl_out_rm=$(find ${_destino}/acl_backup-*.acl -mtime +${_retencao} -exec rm {} \; 2>&$facl_rm_error)
			[ -n $_debug ] && echo "Saida: $facl_out_rm"
			if [ -z $facl_rm_error ]
			then
				echo "Backup com mais de um dia do ACL removido com sucesso."
			else
				_errlog+=${facl_rm_error}
				echo "Não foi possível remover backups antigos do ACL. Verifique arquivo de log $_errlog"
				[ -n $_debug ] && echo "Erro: $facl_rm_error"
			fi
		else
			_errlog+=${facl_error}
			echo "Não foi possível gerar backup do ACL. [Retenção: $_retencao dia(s)]. Verifique arquivo de log $_errlog"
			[ -n $_debug ] && echo "Erro: $facl_error"
		fi
		
		acl_datafinal=`date +%s`
        acl_soma=`expr $acl_datafinal - $acl_datainicial`
        acl_resultado=`expr 10800 + $acl_soma`
        acl_tempo=`date -d @$acl_resultado +%H:%M:%S`
        echo "Tempo de execução do backup das configurações de ACL: $acl_tempo"
        echo ""
	else
		echo "Backup do ACL já realizado."
	fi
	echo "Fim do backup ACL"


	echo "Inicio do backup das configurações do Apache2"
	apc_backupeado=$(find ${_destino}/configapache-*.tar.gz -mtime 0 2>$_errlog | wc -l)
	if [ $apc_backupeado -eq 0 ]
	then
		apc_datainicial=`date +%s`
        apch_out=$($_tar -zcf -C ${_destino}/configapache-{$_id}.tar.gz /etc/apache2/* 2>&$apch_error)
		[ -n $_debug ] && echo "Saida: \n $apch_out"
        if [ -z $apch_error ]
        then
			echo "Backup do Apache2 executado com sucesso."
			apch_out_rm=$(find ${_destino}/configapache-*.tar.gz -mtime +${_retencao} -exec rm {} \; 2>&$apch_rm_error)
			[ -n $_debug ] && echo "Saida: $apch_out_rm"
			if [ -z $apch_rm_error ]
			then
				echo "Backup com mais de um dia das configurações do apache2 removido com sucesso."
			else
				_errlog+=${$apch_rm_error}
				echo "Não foi possível remover backups antigos do Apache2. [Retenção: $_retencao dia(s)] Verifique arquivo de log $_errlog"
				[ -n $_debug ] && echo "Erro: $apch_rm_error"
			fi
			
			apc_datafinal=`date +%s`
			apc_soma=`expr $apc_datafinal - $apc_datainicial`
			apc_resultado=`expr 10800 + $apc_soma`
			apc_tempo=`date -d @$apc_resultado +%H:%M:%S`
			echo "Tempo de execução do backup das configurações de ACL: $apc_tempo"
			echo ""
        else
			echo "Não foi possível gerar backup do Apache2. Verifique arquivo de log $_errlog"
        fi
	else
		echo "Backup do Apache2 já realizado."
	fi
	echo "Fim do backup do Apache2"
	

	echo "Inicio do Backup das pastas filha de: ${_origem}"
	_datainicial=`date +%s`
	for diretorio in $(ls ${_origem}/) ; do
		if [ -d "${_origem}/${diretorio}/" ]
		then
			tmp_datainicial=`date +%s`

			echo "Realizando Backup do diretório $diretorio"

			tamanho_dir=$(du -hcs /var/www/$diretorio 2> $_errlog | sed 's/\s\+/ /g' | cut -d' ' -f1 | head -n 1)
			#tamanho_dir=$(du -h --max-depth=1 /var/www | grep $diretorio | sed 's/\s\+/ /g' | cut -d' ' -f1)
			echo "Tamanho do diretório ${_origem}/${diretorio}/ (${tamanho_dir})"

			backupeado=$(find ${_destino}/${diretorio}*.tar.gz -mtime 0 2>$_errlog | wc -l)
			if [ $backupeado -eq 0 ]
			then
			
				#testar: jogar erros em variavel   > $LOG 2> $ERRLOG   onde   LOG=backup.log  ERRLOG=backup.error.log  xvf
				#$( ERROR=$($_tar --exclude='*.jpa' --exclude='*.zip' --exclude='*.rar' --exclude='*.avi' --exclude='*.mp4' --ignore-failed-read -zcf ${_destino}/${diretorio##*/}_${_id}.tar.gz $diretorio/* 2>&1 1>&$out); ) (out)>&1
				#$_tar --exclude='*.jpa' --exclude='*.zip' --exclude='*.rar' --exclude='*.avi' --exclude='*.mp4' --ignore-failed-read -zcf -C ${_destino}/${diretorio##*/}_${_id}.tar.gz ${_origem}/${diretorio}/* 2>&$ERROR >> $_errlog 
				
				#backup das permissões dos arquivos
				#find ${_origem}/${diretorio}/* -type f |xargs ls -la| awk '{print "chmod "$1" "$NF}' > ${_origem}/${diretorio}/permission_${diretorio}-${_id}.sh 2>$_errlog
				
				echo "Realizando backup das permissões de leitura/escrita/gravação dos arquivos do sistema para o diretorio /${diretorio}"
				
				psf_backupeado=$(find ${_origem}/${diretorio}/permission_${diretorio}-*.sh -mtime 0 2>$_errlog | wc -l)
				if [ $psf_backupeado -eq 0 ]
				then
					_filePermission=${_origem}/${diretorio}/permission_${diretorio}-${_id}.sh
					find ${_origem}/${diretorio}/ -type f | xargs stat -c "%a %U:%G %n" | awk '{print "chown "$2" "$3"\nchmod "$1" "$3}' >$_filePermission 2>&$permfile_error
					[ -n $_debug ] && cat $_filePermission
					if [ -z $permfile_error ]
					then
						echo "Permissões do diretório $diretorio criados com sucesso no arquivo $_filePermission"
					else
						_errlog+=${permfile_error}
						echo "Não foi possível criar arquivo com backup das permissões de arquivos do sistema"
						[ -n $_debug ] && echo $permfile_error
					fi
				else
					echo "Permissões dos arquivos do sistema para a pasta $diretorio já foram realizadas"
				fi
				
			
				ERROR=$($_tar --exclude='*.jpa' --exclude='*.zip' --exclude='*.rar' --exclude='*.avi' --exclude='*.mp4' --ignore-failed-read -zcf -C ${_destino}/${diretorio##*/}_${_id}.tar.gz ${_origem}/${diretorio}/* 2>&1 1>&$OUT);
				if [ -n $ERROR ]
				then 
					echo "Não foi possível realizar backup do diretorio $diretorio"
					[ -n $_debug ] && echo "Erro gerado pela compactação: \n $ERROR"
					[ -n $_debug ] && echo "Saida gerado pela compactação: \n $OUT"
				else
					if [ -e "${_destino}/${diretorio}_${_id}.tar.gz" ]
					then
						echo "Backup pasta $diretorio realizado com sucesso."

						tamanho_cpt=$(du -hs ${_destino}/${diretorio}_${_id}.tar.gz 2>$_errlog | sed 's/\s\+/ /g' | cut -d' ' -f1)

						echo "Tamanho final do arquivo de backup ${_destino}/${diretorio}_${_id}.tar.gz (${tamanho_cpt})"

						#removendo arquivos tar.gz com backup ja realizados para retenção definida em variavel
						web_rm=$(find ${_destino}/${diretorio}*.tar.gz -mtime +${_retencao} -exec rm {}\; 2>&$rmtargz_error)
						if [ -z $rmtargz_error ]
						then
							echo "Backup com mais de um dia do diretorio $diretorio removido com sucesso."
						else
							_errlog+=${rmtargz_error}
							echo "Não foi possível remover backups antigos do diretorio no seguinte critério ${_destino}/${diretorio##*/}*.tar.gz"
							[ -n $_debug ] && echo "Erro: \n $rmtargz_error"
							[ -n $_debug ] && echo "Saida: $web_rm"
						fi
						
						#removendo o arquivo contendo as permissões dos arquivos do sistema para recuperar backup basta executar script que contem caminho completo dos arquivos
						prm_rm=$(find ${_origem}/${diretorio}/permission_${diretorio}-*.sh -mtime +${_retencao} -exec rm {}\; 2>&$perm_error)
						if [ -z $prm_error ]
						then
							echo "Backup com mais de um dia do diretorio do arquivo contendo as permissões de arquivo do sistema para o $diretorio foram removido com sucesso."
						else
							_errlog+=${perm_error}
							echo "Não foi possível remover backups contendo as permissões dos arquivos do sistema para o diretorio ${diretorio}"
							[ -n $_debug ] && echo "Erro: \n $perm_error"
							[ -n $_debug ] && echo "Saida: $prm_rm"							
						fi
					else
						echo "Arquivo de backup ${_destino}/${diretorio}_${_id}.tar.gz não encontrado no diretorio de destino. Backups antigos não seram removidos."
					fi
				fi	
				# _pid=$(pidof tar) && kill -9 ${_pid}
			else
				tamanho_bkp=$(du -hs ${_destino}/${diretorio}_${_id}.tar.gz 2> $_errlog | sed 's/\s\+/ /g' | cut -d' ' -f1)
				echo "Arquivo já criado no dia de hoje. ${_destino}/${diretorio}_${_id}.tar.gz ($tamanho_bkp)";
				echo "Arquivo não criado, passando para o próximo."
			fi

			tmp_datafinal=`date +%s`
			tmp_soma=`expr $tmp_datafinal - $tmp_datainicial`
			tmp_resultado=`expr 10800 + $tmp_soma`
			tmp_tempo=`date -d @$tmp_resultado +%H:%M:%S`
			echo "Tempo de execução da compactação da pasta $diretorio/ [$tmp_tempo]"
			echo ""
		fi
	done

	_datafinal=`date +%s`
	_soma=`expr $_datafinal - $_datainicial`
	_resultado=`expr 10800 + $_soma`
	_tempo=`date -d @$_resultado +%H:%M:%S`
	echo "Tempo de execução das compactações da pasta $_origem => [ $_tempo ]"
	echo ""
fi

