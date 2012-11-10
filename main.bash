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

#manipulacao do item backup mysql
backup_menu(){

	#verifica se o mysql esta rodando e, caso positivo, executa o backup	
	bkp(){
		is_running=`service mysql status | awk -F' ' '{ print $4 }'`
		if [ -n "$is_running" ]
		then
			dialog --title "Aviso" --msgbox "Vou fazer o backup" 0 0
			
		else
			dialog --title "Aviso" --msgbox "Nao vou fazer o backup" 0 0
		fi
	}

	bkp_menu(){
	
		op_backup=$( dialog						\
				--stdout				     	\
				--title "Opcoes com backup Mysql"             	\
				--menu  "Escolha uma opcao"                  	\
				0 0 0 					     	\
				DoBackup "Efetuar backup geral" 	     	\
				Check    "Verificar integridade"        	\
				DoCron   "Agendar um backup"                    \
				Back     "Voltar")

		if [ -n "$op_backup" ]
		then
			case $op_backup in
				"DoBackup") bkp;;
				"Check") dialog --title "Aviso" --msgbox "Checing" 0 0;;
				"DoCron") dialog --title "Aviso" --msgbox "Schedleing" 0 0;;
				"Back") main_menu;;
			esac
		else
			main_menu
		fi

		backup_menu
	}
	
	bkp_menu
}

# incluir usuario
incluir(){
	usuario=$( dialog --stdout --inputbox "Por favor, informe o nome do usuario:" 0 0 )
	if [ -n "$usuario" ]
	then
		senha=$( dialog --stdout --passwordbox "Por favor, informe a senha do usuario:" 0 0 )
	
		useradd $usuario -m  -p $senha
	fi

	user_menu
}

# excluir usuario
excluir(){
	check="";
	usuario=$( dialog --stdout --inputbox "Por favor, informe o nome do usuario:" 0 0 )
	check=`awk -F: '{ print $1 }' /etc/passwd | grep $usuario`
	if [ -n "$check" ]
	then
		userdel $usuario -r
	else
		dialog --title "Aviso" --msgbox "Usuario [$usuario] nao existe." 0 0 
	fi
	
	user_menu
}

# lista os usuarios
listar(){
	awk -F: '{ print $1 }' /etc/passwd > /tmp/out

	dialog --title 'Usuarios do sistema' --textbox /tmp/out 0 0

	user_menu
}

info(){
	usr=$( dialog --stdout --inputbox "Por favor, informe o nome do usuario:" 0 0 )
	chk=`awk -F: '{ print $1 }' /etc/passwd | grep $usr`
	if [ -n "$chk" ]
	then
		dir_home=`cat /etc/passwd | grep $usr | awk -F: '{ print $6 }'`
		shell_usr=`cat /etc/passwd | grep $usr | awk -F: '{ print $7 }'`
		echo "Usuario: $usr" > /tmp/out
		echo "Diretorio home: $dir_home" >> /tmp/out
		echo "Interpretador padrao: $shell_usr" >> /tmp/out
		dialog --title 'Usuarios do sistema' --textbox /tmp/out 0 0
	else
		dialog --title "Aviso" --msgbox "Usuario [$usr] nao existe." 0 0
	fi

	user_menu
} 

# efetua alteracoes no usuario
alterar(){

	# funcao para alterar o home do usuario
	home(){
		usr=$( dialog --stdout --inputbox "Por favor, informe o nome do usuario:" 0 0 )
		chk=`awk -F: '{ print $1 }' /etc/passwd | grep $usr`
		if [ -n "$chk" ]
		then
			dir=$( dialog --stdout --inputbox "Por favor, informe o diretorio:" 0 0 )
			if [ -d $dir ]
			then
				usermod -d $dir $usr
				chown $usr $dir -R
			else
				dialog --title "Aviso" --msgbox "[$dir] deve existir." 0 0
			fi
		else
			dialog --title "Aviso" --msgbox "Usuario [$usr] nao existe." 0 0
		fi

		alterar	
	}

	# funcao para bloquear usuario
	block(){
		usr=$( dialog --stdout --inputbox "Por favor, informe o nome do usuario:" 0 0 )
		chk=`awk -F: '{ print $1 }' /etc/passwd | grep $usr`
		if [ -n "$chk" ]
		then
			if [ "$1" = "b" ]
			then
				passwd -l $usr
			elif [ "$1" = "u" ]
			then
				passwd -u $usr
			fi
		else
			dialog --title "Aviso" --msgbox "Usuario [$usr] nao existe." 0 0
		fi

		alterar
	}

	# funcao para alterar o shell do usuario
	shl(){
		usr=$( dialog --stdout --inputbox "Por favor, informe o nome do usuario:" 0 0 )
		chk=`awk -F: '{ print $1 }' /etc/passwd | grep $usr`
		if [ -n "$chk" ]
		then
			bsh=$( dialog --stdout --inputbox "Por favor, informe o interpretador:" 0 0 )
			if [ -n "$bsh" ]
			then
				usermod -s $bsh $usr
			fi
		else
			dialog --title "Aviso" --msgbox "Usuario [$usr] nao existe." 0 0
		fi
	
		alterar
	}

	senha(){
		usr=$( dialog --stdout --inputbox "Por favor, informe o nome do usuario:" 0 0 )
		chk=`awk -F: '{ print $1 }' /etc/passwd | grep $usr`
		if [ -n "$chk" ]
		then
			pass=$( dialog --stdout --passwordbox "Por favor, informe a nova senha:" 0 0 )
			if [ -n "$pass" ]
			then
				echo -e "$pass\n$pass" | passwd $usr 2>&-
			else
				dialog --title "Aviso" --msgbox "Senha nao pode ser vazia." 0 0
			fi
		else 
			dialog --title "Aviso" --msgbox "Usuario [$usr] nao existe." 0 0
		fi

		alterar
	}

	x=$( dialog					  \
		--stdout				  \
		--title "Alterar usuario"	          \
		--menu "Escolha uma opcao"                \
		0 0 0                                     \
		Home "Alterar diretorio home"             \
		Bloquear "Bloqueia usuario"               \
		Desbloquear "Desbloquear usuario"         \
		Interpretador "Alterar intepretador padrao"\
		Senha "Alterar senha"                      \
		Info "Exibir informacoes do usuario"       \
		Voltar "Volta menu anterior")

	case $x in
		"Home") home;;
		"Bloquear") block b;;
		"Desbloquear") block u;;
		"Interpretador") shl;;
		"Senha") senha;;
		"Info") info;;
		"Voltar") user_menu;;
	esac

	user_menu
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
		"Backup")  backup_menu;; #AQUI DEVE CONTER A FUNCAO QUE CHAMA O MENU PARA TRATAR DO BACKUP MYSQL
		"Servicos") ;; #AQUI DEVE CONTER A FUNCAO QUE CHAMA O MENU PARA LIDAR COM OS SERVICOS
	esac

	exit 0
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
			Listar  "Listar os usuarios do sistema" \
			Info 	"Exibir informacoes de usuarios" \
			Voltar  "Voltar para o menu anterior")

	if [ -n "$op" ]
	then

		case $op in
			"Incluir") incluir;;
			"Excluir") excluir;;
			"Alterar") alterar;;
			"Listar")  listar;;
			"Info") info;;
			"Voltar" ) main_menu;;
		esac
	else
		main_menu
	fi
}

main_menu

exit 0
