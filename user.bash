#!/bin/bash

if [ -n $opcao ] 
then
	op=$( dialog				   \
		--stdout                           \
		--title "Gerenciamento de Usuario" \
		--menu "Escolha uma opcao:"        \
		0 0 0                              \
		Incluir "Incluir um novo usuario"  \
		Excluir "Excluir um usuario"       \
		Alterar "Alterar um usuario" )
else	
	./main.sh 
fi
