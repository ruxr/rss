#!/bin/sh
export LANG=C
OUT="Test Reports/Restore shell script

	@(#) Rss.tst V1.19.2 (C) 2007-2019 by Roman Oreshnikov

This is free software, and comes with ABSOLUTELY NO WARRANTY

Usage: Rss.tst [-n]

Options:
  -n  Don't exit after the first error
  -h  Display this text

Report bugs to <r.oreshnikov@gmail.com>"
#
CON=
while getopts eh TMP; do
	case $TMP in
	n) CON=y;;
	h) echo "$OUT"; exit;;
	?) echo "$OUT"; exit 1
	esac
done
#
WRK=tst
DBF=$WRK/.Rss
LOG=$WRK/Log
INF=$WRK/.inf
ERR=$WRK/.stderr
OUT=$WRK/.stdout
TMP=$WRK/.tmp
REP=$WRK/report
TST=$(pwd)/$WRK
SUM=0
TTY=
LST="$WRK/dir $WRK/dir/file $WRK/dir/link $WRK/dir/none"
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
Sql() { /usr/bin/sqlite3 -separator ' ' "$DBF" "$*"; }
Rss() {
	{ echo -n "\$ Rss"
	for P do
		case $P in *[\ \*]*) echo -n " \"$P\"";; *) echo -n " $P";; esac
	done
	echo
	} >>"$LOG"
	case $1 in -?*) ./Rss -U "$DBF" "$@";; *)./Rss "$@";; esac
	RSS=$?
}
Tst() {
	if [ -n "$TTY" ]; then
		exec 1>"$TTY" 2>&1
		/bin/cat "$ERR" "$OUT" >>"$LOG"
		[ -s "$ERR" ]
		case $?$RSS in
		10) RSS=0;;
		00) RSS=W;;
		0*) RSS=E;;
		*) RSS=
		esac
		[ -n "$RSS" ] && RSS=$RSS$(cat "$ERR" "$OUT" | wc -l)
		if [ "x$RSS" = "x$OPT" ]; then
			echo Ok
		else
			echo Fi
			echo "; $OPT != $RSS" >>"$LOG"
			echo "; $OPT != $RSS"
			SUM=$(expr $SUM + 1)
			[ -n "$CON" ] || shift $#
		fi
	else
		TTY=$(/usr/bin/tty)
		/bin/rm -rf "$WRK" && mkdir -p "$WRK" || exit
		trap Tst 0
		/bin/date "+; Start test: %c" >>"$LOG"
	fi
	if [ $# = 0 ]; then
		trap 0
		/bin/date "+%n; End test: %c" >>"$LOG"
		echo -n "Тестирование завершено (ошибок $SUM)."
		echo " Ход тестирования в файле $LOG"
		exit 0
	fi
	OPT=$1
	shift
	echo -n "   - $@\r"
	echo "\n; $@" >>"$LOG"
	exec 2>"$ERR" >"$OUT"
	RSS=0
}
#
# Tst {0|E|W}{line} Description
#
echo Тестированиe функционирования Rss
Tst 045 Получение справки
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
	Rss -b "$WRK/dir"
Tst E1 Попытка сохранения с заданием имени объектa без указания исходника
	Rss -R "$WRK/dir/none" -b
Tst E1 Попытка сохранения с заданием имени объектa и лишним аргументом
	Rss -R "$WRK/dir/none" -b "$OUT" none
Tst E1 Сохранениe с заданием некорректного имени объектa
	Rss -R " " -b "$OUT"
Tst 00 Сохранениe с заданием имени объектa и датой
	Rss -D " " -R "$WRK/dir/none" -b "$OUT"
Tst 00 Сохранение объектов \(Version 1\)
	mkdir -p "$WRK/dir"
	ln -sf none "$WRK/dir/link"
	echo Version 1 >"$WRK/dir/file"
	Chk >"$INF"
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
Tst 00 Восстановление измененных объектов
	echo >"$WRK/dir/file"
	chmod 660 "$WRK/dir/file"
	rm "$WRK/dir/link"
	ln -sf file "$WRK/dir/link"
	chmod 700 "$WRK/dir"
	chgrp -R 0 "$WRK/dir"
	Rss -nr \*
	Chk | diff -U0 "$INF" -
Tst 00 Восстановление файла вместо каталога
	rm "$WRK/dir/file"
	mkdir "$WRK/dir/file"
	Rss -nr "$WRK/dir/file"
Tst 00 Восстановление файла вместо ссылки
	rm "$WRK/dir/file"
	ln -sf bad "$WRK/dir/file"
	Rss -nr "$WRK/dir/file"
Tst 00 Восстановление ссылки вместо каталога
	rm "$WRK/dir/link"
	mkdir "$WRK/dir/link"
	Rss -nr "$WRK/dir/link"
Tst 00 Восстановление ссылки вместо файла
	rm "$WRK/dir/link"
	touch "$WRK/dir/link"
	Rss -nr "$WRK/dir/link"
Tst 00 Восстановление каталога вместо файла
	rm -rf "$WRK/dir"
	touch "$WRK/dir"
	Rss -nr "$WRK/dir"
Tst 00 Восстановление каталога вместо ссылки
	rm -rf "$WRK/dir"
	ln -s bad "$WRK/dir"
	Rss -nr "$WRK/dir"
Tst 00 Восстановление с нуля
	rm -rf "$WRK/dir"
	Rss -nr \*
	Chk | diff -U0 "$INF" -
Tst E1 Попытка получения последней версии файла на STDOUT без указания имени
	Rss -o >"$TMP"
Tst E1 Попытка получения последней версии файла на STDOUT с лишним аргументом
	Rss -o "$WRK/dir/file" x >"$TMP"
Tst 00 Получение последней версии на STDOUT несуществующего объекта
	Rss -o "$WRK/x"
Tst 00 Получениe последней версии объекта не являющимся файлом на STDOUT
	Rss -o "$WRK/dir/link"
Tst 00 Получениe последней версии удаленного файла на STDOUT
	Rss -o "$WRK/dir/none"
Tst 00 Получение последней версии файла на STDOUT
	Rss -o "$WRK/dir/file" >"$TMP"
	diff -u "$WRK/dir/file" "$TMP"
Tst 00 Сохранение объектов \(Version 2\)
	sleep 1
	V2=$(date +%s)
	mkdir -p "$WRK/dir"
	chmod 770 "$WRK/dir"
	ln -sf file "$WRK/dir/link"
	echo Version 2 >"$WRK/dir/file"
	chmod 640 "$WRK/dir/file"
	Rss -b $LST
	Chk >"$TMP"
Tst 00 Восстановления на заданную дату
	Rss -D "$V1" -rn \*
	Chk | diff -U0 "$INF" -
Tst 00 Восстановление последних версий объектов
	Rss -rn \*
	Chk | diff -U0 "$TMP" -
Tst E1 Попытка восстановления файла в каталоге закрытом для записи
	rm "$WRK/dir/file"
	chmod 555 "$WRK/dir"
	Rss -rn "$WRK/dir/file"
Tst 00 Восстановлениe каталога закрытого для записи
	Rss -rn "$WRK/dir"
Tst 03 Получение списка активных объектов
	Rss -l \*
Tst 08 Получение краткой информации о всех версиях объектов
	Rss -a \*
Tst 08 Получение полной информации о всех версиях объектов
	Rss -an \*
Tst E1 Попытка удаления всех, кроме последней, версий без указания имени объекта
	Rss -e
Tst 00 Полное удаление объекта из БД
	Rss -en "$WRK/dir/none"
	Sql "SELECT p FROM db WHERE p='$WRK/dir/none'"
Tst 00 Удаление всех, кроме последней, версий объектов
	Rss -e \*
	Sql "SELECT p FROM db" | sort >"$TMP"
	sort -u "$TMP" | diff -U0 "$TMP" -
Tst 03 Получение краткой информации о всех версиях объектов
	Rss -a \*
Tst 00 Полная очистка БД
	Rss -en \*
	Sql "SELECT p FROM db" | sort >"$TMP"
Tst 00 Сохранение объекта по имени
	Rss -b -R "$WRK/dir/none" "$LOG"
Tst 00 Повторное сохранение объекта по имени
	Rss -b -R "$WRK/dir/none" "$LOG"
Tst E1 Попытка восстановления объекта с ошибкой в БД
	Sql "UPDATE db SET d='1970-01-01 00:00:00', b='aaaaa' WHERE rowid=1"
	Rss -D 0 -rn \*
Tst E1 Получение последней версии файла на STDOUT для записи с ошибкой в БД
	Sql "UPDATE db SET b='/aaaaa' WHERE rowid=2"
	Rss -o "$WRK/dir/none" >"$TMP"
Tst E1 Обновление объекта для записи с ошибкой в БД
	Rss -b -R "$WRK/dir/none" "$LOG"
Tst 00 Полная очистка БД для тестирования режима отчета
	rm -rf "$WRK/dir"*
	Rss -en \*
	Sql "SELECT p FROM db" | sort >"$TMP"
Tst E1 Попытка запуска Rss в режиме отчета без указания аргумента
	Rss -s
Tst E1 Попытка запуска Rss в режиме отчета для неисполняемого файла
	touch "$REP"
	Rss -s "$REP"
Tst 00 Попытка запуска Rss в режиме отчета для пустого каталога
	mkdir -p "$WRK/dir/rep"
	Rss -s "$WRK/dir/rep"
Tst 024 Подготовка тестовых отчетов в каталоге
	for N in 0 1 2 3; do
		echo "$ cat $WRK/dir/rep/r$N"
		echo "#/bin/sh\necho Report $N\n" | tee "$WRK/dir/rep/r$N"
	done
	chmod 755 "$WRK/dir/rep/r"[1-3]
	echo \$ ls -al "$WRK/dir/rep"
	ls -al "$WRK/dir/rep"
Tst 09 Запуск Rss в режиме отчета для каталога c примерами отчетов
	Rss -s "$WRK/dir/rep"
Tst 016 Формирование тестового отчета с ошибками вызова
	cat <<-END >"$REP"
	Rss "$TST/*"
	Rss "$TST/./dir"
	Rss "$TST/../dir"
	Rss "$TST/d'ir"
	Rss "$TST//dir"
	Rss "$TST/ /dir"
	Rss TST/dir/
	Rss "$TST/dir/" +
	Rss "$TST/dir/" + /a
	Rss "$TST/dir/" + a/./
	Rss "$TST/dir/" + ../b
	Rss "$TST/dir/" + 'a b'
	Rss "$TST/dir/" + a - b
	Rss "$TST/dir" =
	Rss "$TST/dir/rep/r0" = None
	END
	chmod 755 "$REP"
	echo "$ cat $REP"
	cat "$REP"
Tst 045 Запуск Rss в режиме отчета для тестового отчета с ошибками вызова
	Rss -s "$REP"
Tst 026 Формирование тестового отчета
	cat <<-END >"$REP"
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
	chmod 755 "$REP"
	echo "$ cat $REP"
	cat "$REP"
Tst 033 Получение тестового отчета первый раз
	Rss -s "$REP"
Tst 024 Получение тестового отчета повторно
	sleep 1
	Rss -s "$REP"
Tst 018 Формирование тестового отчета работы с файлами
	mkdir -p "$WRK/dir"
	echo >"$WRK/dir/file"
	echo File 0 >"$WRK/dir/file0"
	echo Version 1 >"$WRK/dir/file1"
	{
		echo "root::0::::::"
		echo "mail:x:0::::::"
	} >"$WRK/dir/file2"
	{
		echo "#\n"; echo
		echo "Text"; echo
		echo "Line"; echo
		echo "Word"; echo
		echo "End"; echo
	} >"$WRK/dir/file3"
	cat <<-END >"$REP"
	#!/bin/sh
	Edit() { sed 's/Version/Release/' "\$1"; }
	Diff() {
		diff -U0 "\$1" "\$2" |
		sed 's/^\(.[^: ]*:\)[^:]*/\1(password)/;\$q 1'
	}
	Di() { diff -U1 "\$1" "\$2"; }
	# Файл отсутствует
	Rss "$TST/dir/none"
	# Файл присутствует
	Rss "$TST/dir/file"
	# Сравнение старой и новой версии не производится
	Rss "$TST/dir/file0" = false
	# Нестандартный поиск отличий
	Rss "$TST/dir/file2" = Diff
	# Другое свое сравнение
	Rss "$TST/dir/file3" = Di
	END
	chmod 755 "$REP"
	echo "$ cat $REP"
	cat "$REP"
Tst 035 Получение тестового отчета работы с файлами первый раз
	Rss -s "$REP"
Tst 00 Получение тестового отчета работы с файлами повторно
	sleep 1
	Rss -s "$REP"
Tst 021 Получение тестового отчета работы с файлами после изменений
	rm "$WRK/dir/file"
	echo Version 2 >"$WRK/dir/file1"
	echo "nobody:xxx:0::::::" >>"$WRK/dir/file2"
	echo "#\nappend\n" >>"$WRK/dir/file3"
	chmod 444 "$WRK/dir/file0"
	chmod 600 "$WRK/dir/file2"
	sleep 1
	Rss -s "$REP"
Tst 016 Формирование тестового отчета работы со списками файлов
	echo "$ find $TST/dir | sort | xargs ls -ald"
	find $TST/dir | sort | xargs ls -ald
	echo
	cat <<-END >"$REP"
	#!/bin/sh
	Rss $TST/dir/ + rep = false  Различия не ищутся
	Rss $TST/dir/ - rep
	END
	chmod 755 "$REP"
	echo "$ cat $REP"
	cat "$REP"
	V3=$(date)
Tst 015 Получение тестового отчета работы со списком файлов
	sleep 1
	Rss -s "$REP"
Tst 00 Внесение изменений в тестовые файлы и их сохранение
	echo New >"$WRK/dir/file"
	echo Version 3 >"$WRK/dir/file1"
	echo "user:aa:0::::::" >>"$WRK/dir/file2"
	echo Clean >"$WRK/dir/file3"
	sleep 1
	Rss -b "$TST/dir/"*
Tst 012 Получение всех версий файлов
	Rss -R "$WRK/0" -x \*/file\* && ls "$WRK/0$TST/dir"
Tst 07 Получение всех версий файлов до даты
	Rss -R "$WRK/1" -D "$V3" -x \*file\* && ls "$WRK/1$TST/dir"
Tst 05 Получение всех версий файлов старше даты
	Rss -R "$WRK/2" -D "$V3" -nx \*file\* && ls "$WRK/2$TST/dir"
Tst W1 Получение всех версий файлов старше текущей даты
	Rss -R "$WRK/3" -nx \*file\* && ls "$WRK/3$TST/dir"
