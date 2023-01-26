#!/bin/sh
export LANG=C
WRK="Test Reports/Restore shell script

	@(#) Rss.tst V1.19.2 (C) 2007-2019 by Roman Oreshnikov

This is free software, and comes with ABSOLUTELY NO WARRANTY

Usage: Rss.tst [-n]

Options:
  -h  Display this text
  -n  Don't exit after the first error

Report bugs to <r.oreshnikov@gmail.com>"
#
CON=
while getopts nh I; do
	case $I in
	n) CON=y;;
	h) echo "$WRK"; exit;;
	?) echo "$WRK"; exit 1
	esac
done
#
WRK=$(pwd)
ALL=0
SUM=0
TTY=
LST="dir dir/file dir/link dir/none"
Chk() {
	for P in $LST; do
		I=$(/usr/bin/stat -c '%a %U:%G' "$P" 2>/dev/null)
		echo -n "$P $I "
		if [ -L "$P" ]; then /bin/readlink "$P"
		elif [ -f "$P" ]; then /usr/bin/md5sum "$P" | /bin/sed 's/ .*//'
		else echo
		fi
	done
}
Sql() { /usr/bin/sqlite3 -separator ' ' .Rss "$*"; }
Rss() {
	{ echo -n "\$ Rss"
	for P do
		case $P in *[\ \*]*) echo -n " \"$P\"";; *) echo -n " $P";; esac
	done
	echo
	} >>Log
	case $1 in -?*) ./Rss -U .Rss "$@";; *) ./Rss "$@";; esac
	RSS=$?
}
Tst() {
	ALL=$(expr $ALL + 1)
	if [ -n "$TTY" ]; then
		exec 1>"$TTY" 2>&1
		/bin/cat .err .out >>Log
		[ -s .err ]
		case $?$RSS in
		10) RSS=0;;
		00) RSS=W;;
		0*) RSS=E;;
		*) RSS=
		esac
		[ -n "$RSS" ] && RSS=$RSS$(cat .err .out | wc -l)
		if [ "x$RSS" = "x$OPT" ]; then
			echo Ok
		else
			echo Fi
			echo "; $OPT != $RSS" >>Log
			echo "; $OPT != $RSS"
			SUM=$(expr $SUM + 1)
			[ -n "$CON" ] || shift $#
		fi
	else
		TTY=$(/usr/bin/tty)
		trap Tst 0
		/bin/date "+; Start test: %c" >>Log
	fi
	if [ $# = 0 ]; then
		trap 0
		/bin/date "+%n; End test: %c" >>Log
		echo "	$ALL тестов завершено (ошибок $SUM)"
		echo "	Ход тестирования в файле $WRK/Log"
		exit 0
	fi
	OPT=$1
	shift
	echo -n "   - $@\r"
	echo "\n; $@" >>Log
	exec 2>.err >.out
	RSS=0
}
#
# Tst {0|E|W}{line} Description
#
echo Тестированиe функционирования Rss
Tst 047 Получение справки
	Rss -h
Tst 01 Запуск без ключей и параметров
	Rss
Tst 01 Запуск без ключей
	Rss No keys
Tst E2 Недопустимый ключ
	Rss -E x
Tst E1 Неопределенное действие
	Rss -ab x
Tst E1 Дублирование действия
	Rss -aa x
Tst E1 Неверное задание даты
	Rss -D data -a x
Tst E1 Попытка работы с некорректной таблицей
	Sql "CREATE TABLE db (a)"
	Rss -a x
	Sql "DROP TABLE db"
Tst E1 Попытка сохранения объектa с некорректным именем
	Rss -b . ..
Tst 00 Попытка сохранения несуществующего объекта
	Rss -b dir
Tst E1 Попытка сохранения с заданием имени объектa без указания исходника
	Rss -R dir/none -b
Tst E1 Попытка сохранения с заданием имени объектa и лишним аргументом
	Rss -R dir/none -b .out none
Tst E1 Сохранениe с заданием некорректного имени объектa
	Rss -R " " -b .out
Tst 00 Сохранениe с заданием имени объектa и датой
	Rss -D " " -R dir/none -b .out
Tst 00 Сохранение объектов \(Version 1\)
	mkdir -p dir
	ln -sf none dir/link
	echo Version 1 >dir/file
	Chk >.inf
	Rss -b $LST
	V1=$(date)
Tst 04 Получение списка измененных объектов
	Rss -D "now - 5 minutes" -c \*
Tst 05 Получение информации о всех объектах
	Rss -a \*
Tst 05 Получение полной информации о всех объектах
	Rss -an \*
Tst 03 Получение информации об активных объектах
	Rss -i \*
Tst 03 Восстановление измененных объектов
	echo >dir/file
	chmod 660 dir/file
	rm dir/link
	ln -sf file dir/link
	chmod 700 dir
	chgrp -R 0 dir
	Rss -nr \*
	Chk | diff -U0 .inf -
Tst 01 Восстановление файла вместо каталога
	rm dir/file
	mkdir dir/file
	Rss -nr dir/file
Tst 01 Восстановление файла вместо ссылки
	rm dir/file
	ln -sf bad dir/file
	Rss -nr dir/file
Tst 01 Восстановление ссылки вместо каталога
	rm dir/link
	mkdir dir/link
	Rss -nr dir/link
Tst 01 Восстановление ссылки вместо файла
	rm dir/link
	touch dir/link
	Rss -nr dir/link
Tst 01 Восстановление каталога вместо файла
	rm -rf dir
	touch dir
	Rss -nr dir
Tst 01 Восстановление каталога вместо ссылки
	rm -rf dir
	ln -s bad dir
	Rss -nr dir
Tst 03 Восстановление с нуля
	rm -rf dir
	Rss -nr \*
	Chk | diff -U0 .inf -
Tst E1 Попытка получения последней версии файла на STDOUT без указания имени
	Rss -o >.tmp
Tst E1 Попытка получения последней версии файла на STDOUT с лишним аргументом
	Rss -o dir/file x >.tmp
Tst 00 Получение последней версии на STDOUT несуществующего объекта
	Rss -o x
Tst 00 Получениe последней версии объекта не являющимся файлом на STDOUT
	Rss -o dir/link
Tst 00 Получениe последней версии удаленного файла на STDOUT
	Rss -o dir/none
Tst 01 Получение последней версии файла на STDOUT
	Rss -o dir/file | tee .tmp
	diff -u dir/file .tmp
Tst 00 Сохранение объектов \(Version 2\)
	sleep 1
	V2=$(date +%s)
	mkdir -p dir
	chmod 770 dir
	ln -sf file dir/link
	echo Version 2 >dir/file
	chmod 640 dir/file
	Rss -b $LST
	Chk >.tmp
Tst 03 Восстановления на заданную дату
	Rss -D "$V1" -rn \*
	Chk | diff -U0 .inf -
Tst 03 Восстановление последних версий объектов
	Rss -rn \*
	Chk | diff -U0 .tmp -
Tst E2 Попытка восстановления файла в каталоге закрытом для записи
	rm dir/file
	chmod 555 dir
	Rss -rn dir/file
Tst 01 Восстановлениe каталога закрытого для записи
	Rss -rn dir
Tst 03 Получение списка активных объектов
	Rss -l \*
Tst 08 Получение краткой информации о всех версиях объектов
	Rss -a \*
Tst 08 Получение полной информации о всех версиях объектов
	Rss -an \*
Tst E1 Попытка удаления всех, кроме последней, версий без указания имени объекта
	Rss -e
Tst 05 Удаление всех, кроме последней, версий объектов
	Rss -e \*
	Sql "SELECT p FROM db"
Tst 00 Удаление неактивного объекта из БД
	Rss -en dir/none
	Sql "SELECT p FROM db WHERE p='dir/none'"
Tst 03 Получение краткой информации о всех версиях объектов
	Rss -a \*
Tst 00 Сохранение объекта по имени
	Rss -b -R "dir/none" Log
Tst 00 Повторное сохранение объекта по имени
	Rss -b -R "dir/none" Log
Tst E2 Попытка восстановления объекта с ошибкой в БД
	Sql "UPDATE db SET d='1970-01-01 00:00:00', b='aaaaa' WHERE rowid=2"
	Rss -D 0 -rn \*
Tst E1 Получение последней версии файла на STDOUT для записи с ошибкой в БД
	Sql "UPDATE db SET b='/aaaaa' WHERE p='dir/none'"
	Rss -o dir/none >.tmp
Tst E1 Обновление объекта для записи с ошибкой в БД
	Rss -b -R dir/none Log
Tst 00 Полная очистка БД для тестирования режима отчета
	rm -rf dir
	Sql "DELETE FROM db"
Tst E1 Попытка запуска Rss в режиме отчета без указания аргумента
	Rss -s
Tst E1 Попытка запуска Rss в режиме отчета для неисполняемого файла
	touch Rep
	Rss -s Rep
Tst 00 Попытка запуска Rss в режиме отчета для пустого каталога
	mkdir -p dir/rep
	Rss -s dir/rep
Tst 024 Подготовка тестовых отчетов в каталоге
	for N in 0 1 2 3; do
		echo "$ cat dir/rep/r$N"
		echo "#/bin/sh\necho Report $N\n" | tee dir/rep/r$N
	done
	chmod 755 dir/rep/r[1-3]
	echo \$ ls -al dir/rep
	ls -al dir/rep
Tst 09 Запуск Rss в режиме отчета для каталога c примерами отчетов
	Rss -s dir/rep
Tst 016 Формирование тестового отчета с ошибками вызова
	cat <<-END >Rep
	Rss "$WRK/*"
	Rss "$WRK/./dir"
	Rss "$WRK/../dir"
	Rss "$WRK/d'ir"
	Rss "$WRK//dir"
	Rss "$WRK/ /dir"
	Rss WRK/dir/
	Rss "$WRK/dir/" +
	Rss "$WRK/dir/" + /a
	Rss "$WRK/dir/" + a/./
	Rss "$WRK/dir/" + ../b
	Rss "$WRK/dir/" + 'a b'
	Rss "$WRK/dir/" + a - b
	Rss "$WRK/dir" =
	Rss "$WRK/dir/rep/r0" = None
	END
	chmod 755 Rep
	echo "$ cat Rep"
	cat Rep
Tst 045 Запуск Rss в режиме отчета для тестового отчета с ошибками вызова
	Rss -s Rep
Tst 026 Формирование тестового отчета
	cat <<-END >Rep
	#!/bin/sh
	echo Тестовый отчет
	Rss - Блок с ошибкой, без вывода
		false
	Rss - Блок без ошибки, без вывода
		true
	Rss - Блок с ошибкой, c выводом на STDERR
		echo Error >&2
		[ \$? != 0 ]
	Rss - Блок без ошибки, с выводом на STDOUT
		echo ОК
	Rss - Блок с ошибкой, с выводом на STDERR и STDOUT
		echo Start
		echo Error >&2
		echo Done
		[ \$? != 0 ]
	Rss - Блок без ошибки, с выводом на STDERR и STDOUT
		echo Start
		echo Error >&2
		echo Done
	Rss test/rep0 Блок с ошибкой, сохранение результата в файл
		echo Report 0
		[ \$? != 0 ]
	Rss test/rep1 Блок без ошибки, сохранение результата в файл
		echo Report 1
	END
	chmod 755 Rep
	echo "$ cat Rep"
	cat Rep
Tst 033 Получение тестового отчета первый раз
	Rss -s Rep
Tst 024 Получение тестового отчета повторно
	sleep 1
	Rss -s Rep
Tst 018 Формирование тестового отчета работы с файлами
	mkdir -p dir
	echo >dir/file
	echo File 0 >dir/file0
	echo Version 1 >dir/file1
	{
		echo "root::0::::::"
		echo "mail:x:0::::::"
	} >dir/file2
	{
		echo "#\n"; echo
		echo "Text"; echo
		echo "Line"; echo
		echo "Word"; echo
		echo "End"; echo
	} >dir/file3
	cat <<-END >Rep
	#!/bin/sh
	Edit() { sed 's/Version/Release/' "\$1"; }
	Diff() {
		diff -U0 "\$1" "\$2" |
		sed 's/^\(.[^: ]*:\)[^:]*/\1(password)/;\$q 1'
	}
	Di() { diff -U1 "\$1" "\$2"; }
	# Файл отсутствует
	Rss "$WRK/dir/none"
	# Файл присутствует
	Rss "$WRK/dir/file"
	# Сравнение старой и новой версии не производится
	Rss "$WRK/dir/file0" = false
	# Нестандартный поиск отличий
	Rss "$WRK/dir/file2" = Diff
	# Другое свое сравнение
	Rss "$WRK/dir/file3" = Di
	END
	chmod 755 Rep
	echo "$ cat Rep"
	cat Rep
Tst 035 Получение тестового отчета работы с файлами первый раз
	Rss -s Rep
Tst 00 Получение тестового отчета работы с файлами повторно
	sleep 1
	Rss -s Rep
Tst 021 Получение тестового отчета работы с файлами после изменений
	rm dir/file
	echo Version 2 >dir/file1
	echo "nobody:xxx:0::::::" >>dir/file2
	echo "#\nappend\n" >>dir/file3
	chmod 444 dir/file0
	chmod 600 dir/file2
	sleep 1
	Rss -s Rep
Tst 016 Формирование тестового отчета работы со списками файлов
	echo "$ find dir | sort | xargs ls -ald"
	find dir | sort | xargs ls -ald
	echo
	cat <<-END >Rep
	#!/bin/sh
	Rss $WRK/dir/ + rep = false  Различия не ищутся
	Rss $WRK/dir/ - rep
	END
	chmod 755 Rep
	echo "$ cat Rep"
	cat Rep
Tst 015 Получение тестового отчета работы со списком файлов
	sleep 1
	V3=$(date)
	Rss -s Rep
Tst 00 Внесение изменений в тестовые файлы и их сохранение
	echo New >dir/file
	echo Version 3 >dir/file1
	echo "user:aa:0::::::" >>dir/file2
	echo Clean >dir/file3
	sleep 1
	Rss -b "$WRK/dir/"*
Tst 012 Получение всех версий файлов
	Rss -R 0 -x \*/file\* && ls 0$WRK/dir
Tst 05 Получение всех версий файлов старше даты
	Rss -R 1 -D "$V3" -x \*file\* && ls 1$WRK/dir
Tst 00 Очищаем БД для тестирования удаления и вывода различий
	Sql "DELETE FROM db"
Tst 02 Первая версия файла
	echo 0 >a
	echo "$ cat a"
	cat a
	Rss -b a
	D0=$(date)
	sleep 1
Tst 02 Вторая версия файла
	echo 1 >a
	echo "$ cat a"
	cat a
	Rss -b a
	D1=$(date)
	sleep 1
Tst 01 Третья версия файла
	rm a
	echo "$ rm a"
	Rss -b a
	D2=$(date)
	sleep 1
Tst 02 Четвертая версия файла
	echo 1 >a
	echo "$ cat a"
	cat a
	Rss -b a
	sleep 1
Tst 02 Пятая версия файла
	echo -1 >a
	echo "$ cat a"
	cat a
	Rss -b a
	D3=$(date)
	sleep 1
Tst 02 Шестая версия файла
	echo 1 >a
	echo "$ cat a"
	cat a
	Rss -b a
	sleep 1
Tst 02 Седьмая версия файла
	echo 2 >a
	echo "$ cat a"
	cat a
	Rss -b a
	sleep 1
Tst 02 Восьмая версия файла
	echo 3 >a
	echo "$ cat a"
	cat a
	Rss -b a
Tst 08 Проверяем количество объектов
	Rss -an \*
Tst E1 Удаляем несуществующий объект
	Rss -z b
Tst 05 Различия содержимого на заданную дату
	Rss -D "$D1" -d a
Tst 01 Удаляем самый старый файл
	Rss -D "$D0" -zn a
Tst 04 Различия содержимого на заданную дату
	Rss -D "$D1" -d a
Tst 01 Удаляем отметку удаления, где версии до и после удаления идентичны
	Rss -D "$D2" -zn a
Tst 05 Проверка наличия объектов в БД
	Rss -an a
Tst 01 Удаляем файл, где версии до и после него идентичны
	Rss -D "$D3" -zn a
Tst 03 Проверка наличия объектов в БД
	Rss -an a
Tst 05 Различия между предпоследней и последней версиями файла
	Rss -d a
Tst 01 Удаляем последнюю версию файла
	Rss -zn a
Tst 05 Различия между предпоследней и последней версиями файла
	Rss -d a
Tst 01 Оставляем единственный самый старый вариант
	Rss -zn a
Tst 04 Различия для единственного варианта
	Rss -d a
Tst 01 Окончательное удаление объекта
	Rss -zn a
Tst 00 Проверка на отсутствие объектов
	Rss -an \*
