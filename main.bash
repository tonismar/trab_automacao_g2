#!/bin/bash
###############################################
#                                             #
# Trabalho G2 - Sistema de Automacao          #
# Grupo: Andre, Franciele, Jorge e Tonismar   #
#                                             #
###############################################

# verifica se o usuario e root
if [ $UID -ne 0 ]
then
	dialog --title "Aviso" --msgbox "E necessario ser root para executar o script" 0 0
	exit 0
fi

# incluir usuario
incluir(){
	usuario=$( dialog --stdout --inputbox "Por favor, informe o nome do usuario:" 0 0 )
	senha=$( dialog --stdout --passwordbox "Por favor, informe a senha do usuario:" 0 0 )
	useradd $usuario -m  -p $senha
}

# excluir usuario
excluir(){
	check="";
	usuario=$( dialog --stdout --inputbox "Por favor, informe o nome do usuario:" 0 0 )
	check=`awk -F: '{ print $1 }' /etc/passwd | grep $usuario`
	if [ "$check" = "$usuario" ]
	then
		userdel $usuario -r
	else
		dialog --title "Aviso" --msgbox "Usuario [$usuario] nao existe."0 0 
	fi
}

# menu principal da aplicacao
main_menu(){
	opcao=$( dialog							\
			--stdout				     	\
			--title "Trabalho G1" 		             	\
			--menu  "Escolha uma opcao"                  	\
			0 0 0 					     	\
			Usuario   "Gerencimento de Usuario" 	     	\
			Backup    "Gerenciamento de Backup (MySQL)"  	\
			Servicos "Monitoramento de Sistema/Servico" )
	
	case $opcao in
		"Usuario") user_menu;;
	esac
}

#menu para lidar com operacoes do usuario
user_menu(){
	op=$( dialog                                         \
			--stdout			     \
			--title "Gerenciamento de Usuario"   \
			--menu "Escolha uma opcao:"          \
			0 0 0                                \
			Incluir "Incluir um novo usuario"    \
			Excluir "Excluir um usuario"         \
			Alterar "Alterar um usuario"         \
			Voltar  "Voltar para o menu anterior")

	case $op in
		"Incluir") incluir;;
		"Excluir") excluir;;
		"Alterar") alterar;;
		"Voltar" ) main_menu;;
	esac
}

main_menu
