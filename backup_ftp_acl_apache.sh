#!/bin/bash

#Create by 2º Ten Marcelo Valvassori BITTENCOURT
#Script para realizar o Backup das configuracoes de FTP, Apache e de ACL em sistemas Linux do tipo Debian
#v1.0 - 14/10/2020 | Exercito Brasileiro - 1CTA - (SGO) Seção de Gerenciamento das Operações 
#v1.1 - 23/11/2020 | Adição e remoção de backup antigos do ACL após execução com sucesso de backup do mesmo.

datainicial=`date +%s`

_origem=/var/www     		#origem dos backups
_destino=/mapeamento 	#destino do backup (preferencialmente um disco mapeado)

_tar=$(which tar)
_id=$(date +"%Y-%m-%d")

_retencao=1             			#valor em dias / remover arquivos com mais de X dias

instalado=$(dpkg --get-selections | grep -c tar)
if [ "$instalado" -ne "0" ]; then

        echo "Inicio do backup das configurações de FTP..."
        $_tar -zcf ${_destino}/proftpd-${_id}.tar.gz /etc/proftpd/*
        if [ $? -eq 0 ]
        then
                echo "Backup das configurações do FTP concluidas com sucesso!"
                echo "Iniciando remoção de arquivos de backup do FTP com mais de ${_retencao} dia(s)..."
                find ${_destino}/proftpd-*.tar.gz -mtime +${_retencao} -exec rm {} \;
                if [ $? -eq 0 ]
                then
                        echo "'Backup com mais de ${_retencao} dia(s) do FTP removido(s) com sucesso!"
                else
                        echo "Não foi possível remover backups antigos do FTP!"
                fi
        else
                echo "Não foi possível gerar backup das configurações do FTP!"
        fi

		# _pid=$(pidof tar) && kill -9 ${_pid}
	
		echo "Backup do ACL iniciado, para  restaurar: setfacl --restore=acl_backup-${_id}.acl"
        acl_datainicial=`date +%s`
        echo "Inicio do backup ACL..."
        echo "Destino do arquivo: ${_destino}"
        find ${_destino}/acl_backup-*.acl -mtime +1 -exec getfacl -R ${_origem} > ${_destino}/acl_backup-${_id}.acl \;
        if [ $? -eq 0 ]
        then
                echo "Backup do ACL executado com sucesso!"
                echo "Iniciando processo de remoção de arquivos de backup do ACL com mais de ${_retencao} dia(s)..."
                find ${_destino}/acl_backup-*.acl -mtime +${_retencao} -exec rm {} \;
                if [ $? -eq 0 ]
                then
                        echo "Backup com mais de um ${_retencao} dias do ACL removidos com sucesso!"
                else
                        echo "Não foi possível remover backups antigos do ACL!"
                fi
        else
                echo "Não foi possível gerar backup do ACL!"
        fi

        acl_datafinal=`date +%s`
        acl_soma=`expr $acl_datafinal - $acl_datainicial`
        acl_resultado=`expr 10800 + $acl_soma`
        acl_tempo=`date -d @$acl_resultado +%H:%M:%S`
        echo "Tempo de execução do backup ACL: ${acl_tempo}"

        echo "Inicio do Backup das configurações do apache..."
        find ${_destino}/configapache-*.tar.gz -mtime +1 -exec $_tar -zcf -C ${_destino}/configapache-{$_id}.tar.gz /etc/apache2/* \;
		
		for diretorio in $(ls ${_origem}/) ; do
                if [ -d "${_origem}/${diretorio}/" ]
                then
                        _datainicial=`date +%s`

                        echo "Realizando backup do diretório ${diretorio}/"

                        tamanho_dir=$(du -hcs /var/www/$diretorio | sed 's/\s\+/ /g' | cut -d' ' -f1 | head -n 1)
                        #tamanho_dir=$(du -h --max-depth=1 /var/www | grep $diretorio | sed 's/\s\+/ /g' | cut -d' ' -f1)
                        echo "Tamanho do diretório ${_origem}/${diretorio}/ (${tamanho_dir})"

                        backupeado=$(find ${_destino}/${diretorio}*.tar.gz -mtime 0 | wc -l)
                        if [ $backupeado -eq 0 ]
                        then
                                #testar: jogar erros em variavel   > $LOG 2> $ERRLOG   onde   LOG=backup.log  ERRLOG=backup.error.log  xvf
                                #$( ERROR=$($_tar --exclude='*.jpa' --exclude='*.zip' --exclude='*.rar' --exclude='*.avi' --exclude='*.mp4' -zcf ${_destino}/${diretorio##*/}_${_id}.tar.gz $diretorio/* 2>&1 1>&$out); ) (out)>&1
                                $_tar --exclude='*.jpa' --exclude='*.zip' --exclude='*.rar' --exclude='*.avi' --exclude='*.mp4' --ignore-failed-read -zcf -C ${_destino}/${diretorio##*/}_${_id}.tar.gz ${_origem}/${diretorio}/* >/dev/null 2>&1
                                if [ $? -eq 0 ]
                                then
                                        echo "Backup pasta/diretorio ${diretorio} realizado com sucesso!"
                                        tamanho_cpt=$(du -hs ${_destino}/${diretorio}_${_id}.tar.gz | sed 's/\s\+/ /g' | cut -d' ' -f1)
                                        echo "Tamanho final do arquivo de backup localizado em ${_destino}/${diretorio}_${_id}.tar.gz (${tamanho_cpt})"

                                        find ${_destino}/${diretorio##*/}*.tar.gz -mtime +${_retencao} -exec rm {} \;
                                        if [ $? -eq 0 ]
                                        then
                                                echo "Backup com mais de ${_retencao} dia(s) do diretorio ${diretorio} foi removido com sucesso!"
                                        else
                                                echo "Não foi possível remover backups antigos do diretorio no seguinte critério ${_destino}/${diretorio##*/}*.tar.gz"
                                        fi
                                else
                                        echo "Não foi possível realizar backup do diretorio ${diretorio}"
                                        #echo "Erro gerado pela compactação: ${ERROR}"
                                fi
								# _pid=$(pidof tar) && kill -9 ${_pid}
                        else
                                tamanho_bkp=$(du -hs ${_destino}/${diretorio}_${_id}.tar.gz | sed 's/\s\+/ /g' | cut -d' ' -f1)
                                echo "Arquivo já criado no dia de hoje. ${_destino}/${diretorio}_${_id}.tar.gz ($tamanho_bkp)";
                                echo "Arquivo não criado, passando para o próximo..."
                        fi

                        _datafinal=`date +%s`
                        _soma=`expr $_datafinal - $_datainicial`
                        _resultado=`expr 10800 + $_soma`
                        _tempo=`date -d @$_resultado +%H:%M:%S`
                        echo "Tempo de execução da compactação: ${_tempo}"
                        echo ""
                fi
        done
fi


datafinal=`date +%s`
soma=`expr $datafinal - $datainicial`
resultado=`expr 10800 + $soma`
tempo=`date -d @$resultado +%H:%M:%S`
echo "Tempo de execução do script: ${tempo}"
