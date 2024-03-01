#!/bin/bash
#Скрипт был частично спизжен с https://github.com/Rhsameera/LINUX_AD_JOIN
set -e

#Сокращение.
sssd=/etc/sssd/sssd.conf
gpo=ad_gpo_access_control
name=use_fully_qualified_names

echo "Запуск..."

#Запрос данных для входа в домен.
read -p "Введите имя доменного пользователя с правами администратора: " adm
read -p "Введите полное имя домена: " dmn
host=$(hostnamectl hostname)

#Установка необходимых пакетов.
apt update
apt install -y realmd krb5-user

pack=$(realm discover $dmn | grep 'package' | awk '{print $2}')

if [[ -n $pack ]]; then
		apt install -y $pack
fi

#Вход в домен.
echo -e "Пакеты \e[1;32mустановлены\e[0m.\nВведите пароль для входа в домен - \e[1;33m$dmn\e[0m."
join=$(realm join --verbose $dmn --user=$adm --user-principal="host/$host@$dmn" --install=/)

if [[ $? -eq 0 ]]; then
		echo -e "\e[1;32mЭтот компьютер подключился к домену.\e[0m"
fi

#Настройка SSSD.
if ! grep -q "$gpo = permissive" $sssd ; then
		echo "$gpo = permissive" >> $sssd
		echo "Опция $gpo добавлена."
	else
		echo "Опция $gpo уже включена или sssd.conf не существует."
fi

if grep -q "$name = True" $sssd; then
		sed -i "s/$name = True/$name = False/g" $sssd
		echo "Опция $name выключена."
	else
		echo "Опция $name уже выключена или sssd.conf не существует."
fi

systemctl restart sssd

#Включение mkhomedir.
echo -e "Включите функцию - \e[1;33mCreate home directory on login.\e[0m"
sleep 2
echo -e "Включите функцию - \e[1;33mCreate home directory on login..\e[0m"
sleep 2
echo -e "Включите функцию - \e[1;33mCreate home directory on login...\e[0m"
sleep 3
pam-auth-update
echo -e "\e[1;32mНастройка завершена!\e[0m"
