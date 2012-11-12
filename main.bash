#!/bin/bash
##############################################################################
#                                                                            #
# Trabalho G2 - Sistema de Automacao                                         #
#                                                                            #
#                                                                            #
# Para efetuar a rotina de backup no mysql e necessario a troca de chave SSH #
# entre o computador local e o remoto para nao solicitar senha.              #
#                                                                            #
# 1- Maquina local execute: ssh-keygen -t rsa                                #
# 2- scp ~/.ssh/id_rsa.pub usuario@maquina_remota /tmp/                      #
# 3- Maquina remota execute: cat /tmp/id_rsa.pub >> ~/.ssh/authorized_keys   #
#																			 #
##############################################################################

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
			dialog --stdout --title "AVISO!" --yesno "Efetuar o backup?" 0 0
			if [ $? = 0 ]
			then
				senha=$( dialog --stdout --title 'Senha' --passwordbox 'Informe a senha' 0 0 )
				if [ -n "$senha" ]
				then
					mysqldump -u root -p$senha -x -e -A > /root/backup_all_`date +%Y%m%d%H%M`.sql
				fi
				if [ $? = 0 ]
				then
					tmp=`date +%Y%m%d%H%M`
					md5=`md5sum /root/backup_all_$tmp.sql | awk -F' ' '{ print $1 }'`
					echo "backup|`date`|/root/backup_all_$tmp.sql|$md5" >> /root/backup.log
					#dialog --title "Aviso" --msgbox "Backup efetuado com sucesso." 0 0
					bkp_usuario=$( dialog --stdout --title "Usuario remoto" --inputbox "Informe o usuario remoto." 0 0)
					bkp_host=$( dialog --stdout --title "Computador remoto" --inputbox "Informe o IP/Nome host computador remoto." 0 0 )
					bkp_path=$( dialog --stdout --title "Caminho remoto" --inputbox "Informe o caminho no computador remoto." 0 0 )
					if [ -n "$bkp_usuario" ] && [ -n "$bkp_host" ] && [ -n "$bkp_path" ]
					then
						scp /root/backup_all_`date +%Y%m%d%H%M`.sql $bkp_usuario@$bkp_host:$bkp_path > /dev/null
						if [ $? = 0 ]
						then
							dialog --title "Aviso" --msgbox "Arquivo enviado com sucesso." 0 0
						else
							dialog --title "Erro" --msgbox "Erro ao enviar arquivo. $bkp_usuario $bkp_host $bkp_path" 0 0 
						fi
					else
						dialog --title "Erro" --msgbox "Erro ao informar dados para copia." 0 0 	
					fi
				else
					dialog --title "Aviso" --msgbox "Erro ao efetuar o backup." 0 0
				fi
			fi
			
		else
			dialog --title "Aviso" --msgbox "Servico mysqld nao esta rodando." 0 0
		fi
	}

	bkp_schedule(){
		#minuto hora dia-do-mes mes dia-da-semana comando
		minuto=$( dialog --stdout --title 'Informe o minuto' --inputbox 'Minuto de agendamento' 0 0 )
		hora=$( dialog --stdout --title 'Informe a hora.' --inputbox 'Hora de agendamento' 0 0 )
		dia=$( dialog --stdout --title 'Informe o dia.' --inputbox 'Dia de agendamento' 0 0 )
		mes=$( dialog --stdout --title 'Informe o mes.' --inputbox 'Mes de agendamento' 0 0 )
		dow=$( dialog --stdout --title 'Informe o dia da semana.' --inputbox 'Dia da semana' 0 0 )
		cmd="mysqldump -u root -proot -x -e -A > /root/backup_all_\`date \+\%Y\%m\%d\%H%M\`.sql"
		echo "$minuto $hora $dia $mes $dow $cmd" > /tmp/cron.root
		crontab -u root /tmp/cron.root 2> /tmp/cron.error
		if [ $? = 0 ]
		then
			dialog --title "Aviso" --msgbox "Comando agendado." 0 0
		else
			dialog --title "Aviso" --msgbox "Erro ao executar o agendamento." 0 0
			dialog --title "Erro" --textbox /tmp/cron.error 0 0
		fi
	}

	check_bkp(){
		local_file=$( dialog --stdout --title "Arquivo local" --inputbox "Informe o arquivo (caminho completo) local." 0 70 )
		remote_file=$( dialog --stdout --title "Arquivo remoto" --inputbox "Informe o arquivo (caminho completo) remoto." 0 70 )
		check_user=$( dialog --stdout --title "Usuario remoto" --inputbox "Informe o usuario remoto." 0 0 )
		check_host=$( dialog --stdout --title "Computador remoto" --inputbox "Informe o IP/Nome host computador remoto." 0 0 )
		if [ -n "$check_user" ] && [ -n "$check_host" ] && [ -n "$remote_file" ]
		then		
			remote_md5=`ssh $check_user@$check_host "md5sum $remote_file" | awk -F' ' '{ print $1 }'`
			local_md5=`md5sum $local_file | awk -F' ' '{ print $1 }'`
			if [ "$remote_md5" = "$local_md5" ]
			then
				dialog --title "Aviso" --msgbox "Arquivo integros." 0 0 
			else
				dialog --title "Erro" --msgbox "Arquivos diferentes." 0 0 
			fi
		else
			dialog --title "Erro" --msgbox "Erro ao envio dos dados." 0 0
		fi
	}			

	bkp_menu(){
	
		op_backup=$( dialog						 \
				--stdout				     	 \
				--title "Opcoes com backup Mysql"\
				--menu  "Escolha uma opcao"      \
				0 0 0 					     	 \
				Backup "Efetuar backup geral"  \
				Check    "Verificar integridade" \
				Agendar  "Agendar um backup"     \
				Voltar   "Voltar")

		if [ -n "$op_backup" ]
		then
			case $op_backup in
				"Backup") bkp;;
				"Check") check_bkp;;
				"Agendar") bkp_schedule;;
				"Voltar") main_menu;;
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

