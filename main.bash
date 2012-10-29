#!/bin/bash
###############################################
#                                             #
# Trabalho G2 - Sistema de Automacao          #
# Grupo: Andre, Franciele, Jorge e Tonismar   #
#                                             #
###############################################

opcao=$( dialog							\
		--stdout				     	\
		--title "Trabalho G1" 		             	\
		--menu  "Escolha uma opcao"                  	\
		0 0 0 					     	\
		Usuario   "Gerencimento de Usuario" 	     	\
		Backup    "Gerenciamento de Backup (MySQL)"  	\
		Servicos "Monitoramento de Sistema/Servico" )



# Dependendo a opcao escolhida no menu acima este case
# ira chamar o script especifico
case $opcao in
	"Usuario") ./user.bash $opcao;;
	"Backup")  ./backup.bash;;
	"Servicos") ./servicos.bash;;
esac
