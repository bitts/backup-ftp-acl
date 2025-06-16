#!/bin/bash

#Create by Marcelo Valvassori Bittencourt
#Exercito Brasileiro - 1º Centro de Telemática de Área - 1º CTA
#v1.0 - 14/10/2020 | SGO - Seção de Gerenciamento das Operações | script de backup por pasta
#v1.1 - 23/11/2020 | Adição de remoção de backup antigos do ACL após execução com sucesso de backup do mesmo.
#v1.2 - 17/03/2021 | Correções diversas e logs de erro em arquivo
#v1.3 - 13/07/2021 | Adição de testes logicos para poder rodar script e cancela-lo sempre que necessário sem perdas e sem que o mesmo realize backup de arquivos que já foram realizados
#v1.4 - 15/07/2021 | organizando tudo em functions

datainicial=`date +%s`

_origem=/var/www        #origem dos backups
_destino=/backup/1cta      #destino do backup

_tar=$(which tar)
_id=$(date +"%Y-%m-%d")

_retencao=1             #valor em dias / remover arquivos com mais de X dias
_errlog=/tmp/err-bkp_${_id}.log

_debug=true


pftp_error=/tmp/pftp_error.log
pftp_out=/tmp/pftp_out.log

bkp_ftp_rm(){
        echo "Procurando arquivos de backup antigos das configurações do FTP. [Retenção: $_retencao]\n"
        find ${_destino} -name "proftpd-*.tar.gz" -mtime -${_retencao} -exec rm {} \; 1>&$pftp_out 2>&$pftp_error
        [ -n $_debug ] && printf %20s | sed 's/ /-/g' && printf "\n Saida \n" && cat $pftp_out
        if [ -z $pftp_error ]
        then
                echo "Backup com mais de um dia do proFTPd removido com sucesso.\n"
                rm $pftp_out
        else
                cat $pftp_error >> $_errlog
                echo "Não foi possível remover backups antigos do proFTPd. Verifique arquivo de log $_errlog\n"
                [ -n $_debug ] && printf "Erro: \n" && cat $pftp_error
                rm $pftp_error
        fi
        echo "Termino da procura e remoção de backup antigos.\n"
}

bkp_ftp(){
        echo "Iniciando procedimento de backup do FTP...\n"
        instalado=$(dpkg --get-selections | grep -c tar)
        if [ "$instalado" -ne "0" ]; then
        echo "Inicio do backup de FTP.\n"
        ftp_backupeado=$(find ${_destino} -name "proftpd-*.tar.gz" -mtime 0 2>&$_errlog | wc -l)
        if [ $ftp_backupeado -eq 0 ]
        then
                        ftp_datainicial=`date +%s`
                        #backup das configurações de ftp
                        $_tar -zcf ${_destino}/proftpd-${_id}.tar.gz /etc/proftpd/* 2>$pftp_error 1>$pftp_out
                        [ -n $_debug ] && printf %20s | sed 's/ /-/g' && printf "\n Saida \n" && cat $pftp_out
                        if [ -z $pftp_out ]
                        then
                                echo "Backup do proFTPd executado com sucesso.\n"
                                bkp_ftp_rm
                        else
                                cat $pftp_error >> $_errlog
                                echo "Não foi possível gerar backup das configurações do proFTPd. Verifique arquivo de log $_errlog \n"
                                [ -n $_debug ] && printf "Erro: \n" && cat $pftp_error
                                rm $pftp_error
                        fi

                        ftp_datafinal=`date +%s`
                        ftp_soma=`expr $ftp_datafinal - $ftp_datainicial`
                        ftp_resultado=`expr 10800 + $ftp_soma`
                        ftp_tempo=`date -d @$ftp_resultado +%H:%M:%S`
                        echo "Tempo de execução do backup das configurações de FTP: $ftp_tempo \n"
        else
                        echo "Backup do proFTPd já realizado.\n"
                        bkp_ftp_rm
        fi
        echo "Fim da execução do script de backup FTP.\n"

        # _pid=$(pidof tar) && kill -9 ${_pid}
        else
                echo "Não instalado biblioteca $_tar \n"
        fi
        echo "Termino da procedimento de backup do FTP \n"
}


facl_out=/tmp/facl_out.log
facl_error=/tmp/facl_error.log

bkp_acl_rm(){
        echo "Inicio da remoção de backups antigos do facl...\n"
        find ${_destino} -name "acl_backup-*.acl" -mtime -${_retencao} -exec rm {} \; 1>&$facl_out 2>&$facl_error
        [ -n $_debug ] && printf %20s | sed 's/ /-/g' && printf "\n Saida \n" && cat $facl_out
        if [ -z $facl_error ]
        then
                echo "Backup com mais de um dia do ACL removido com sucesso.\n"
        else
                cat $facl_error >> $_errlog
                echo "Não foi possível remover backups antigos do ACL. Verifique arquivo de log $_errlog \n"
                [ -n $_debug ] && printf "Erro: \n" && cat $facl_error
        fi
        echo "Termino da remoção de backups antigos do facl.\n"
}

bkp_acl(){
        echo "Inicio do backup ACL...\n"
        acl_backupeado=$(find ${_destino} -name "acl_backup-*.acl" -mtime 0 2>$_errlog | wc -l)
        if [ $acl_backupeado -eq 0 ]
        then
                acl_datainicial=`date +%s`
                getfacl -R ${_origem} > ${_destino}/acl_backup-${_id}.acl 2>&$facl_error 1>&$facl_out
                [ -n $_debug ] &&  printf %20s | sed 's/ /-/g' && printf "\n Saida \n" && cat $facl_out
                if [ -z $facl_out ]
                then
                        echo "Backup do ACL executado com sucesso.\n"
                        bkp_acl_rm
                else
                        cat $facl_error >> $_errlog
                        echo "Não foi possível gerar backup do ACL. [Retenção: $_retencao dia(s)]. Verifique arquivo de log $_errlog \n"
                        [ -n $_debug ] && printf "Erro: \n" && cat $facl_error
                fi

        acl_datafinal=`date +%s`
        acl_soma=`expr $acl_datafinal - $acl_datainicial`
        acl_resultado=`expr 10800 + $acl_soma`
        acl_tempo=`date -d @$acl_resultado +%H:%M:%S`
        echo "Tempo de execução do backup das configurações de ACL: $acl_tempo \n"
        else
                echo "Backup do ACL já realizado.\n"
                bkp_acl_rm
        fi
        echo "Fim do backup ACL.\n"
}

bkp_ftp
bkp_acl

