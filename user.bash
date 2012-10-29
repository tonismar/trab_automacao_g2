#!/bin/bash

if [ $UID -ne 0 ]
then
	dialog --title "Aviso" --msgbox "E necessario ser root para executar o script." 0 0
	exit 0
fi

opcao=$1

incluir(){
	usuario=$( dialog --stdout --inputbox "Por favor, informe o nome do usuario:" 0 0 )
	senha=$( dialog	--stdout --passwordbox "Por favor, informe a senha do usuario:" 0 0 )
	useradd $usuario -m -p $senha
}

excluir(){
	check="";
	usuario=$( dialog --stdout --inputbox "Por favor, informe o nome do usuario:" 0 0 )
	check=`awk -F: '{ print $1 }' /etc/passwd | grep $usuario`
	if [ "$check" = "$usuario" ]
	then
		userdel $usuario -r
	else
		dialog --title "Aviso" --msgbox "Usuario [$usuario] nao existe." 0 0
	fi
}

alterar(){
	echo "Alterar"
}

menu(){
        op=$( dialog                               \
                --stdout                           \
                --title "Gerenciamento de Usuario" \
                --menu "Escolha uma opcao:"        \
                0 0 0                              \
                Incluir "Incluir um novo usuario"  \
                Excluir "Excluir um usuario"       \
                Alterar "Alterar um usuario"       \
		Voltar  "Voltar para menu anterior")
}

if [ "$opcao" = "" ] 
then
	./main.bash
else
	menu

	case $op in
		"Incluir") incluir;;
		"Excluir") excluir;;
		"Alterar") alterar;;
		"Voltar" ) ./main.bash
	esac
fi
