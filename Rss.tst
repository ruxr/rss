#
#	@(#) Rss.tst V1.23 (C) 2023 by Roman Oreshnikov
#
install $RUN .
RUN=./Rss
Rss() { case $1 in -[abcdDeilnorRsxz]*) Run -U .Rss "$@";; *) Run "$@";; esac; }
Get() { echo "$(stat -c '%Y %a %U:%G' $1) $(cat $1)"; }
Sql() { sqlite3 -separator ' ' .Rss "$*"; }
LST="dir dir/file dir/link dir/none"
Chk() {
	for P in $LST; do
		echo -n "$P $(stat -c '%a %U:%G' "$P" 2>/dev/null) "
		if [ -L "$P" ]; then readlink "$P"
		elif [ -f "$P" ]; then md5sum "$P" | sed 's/ .*//'
		else echo
		fi
	done
}
#
# Собственно тесты
#
Tst 0:48 Получение справки
	Rss -h
Tst 0:2 Запуск без ключей и параметров
	Rss
Tst 0:2 Запуск без ключей
	Rss No keys
Tst 1:3 Недопустимый ключ
	Rss -E x
Tst 1:2 Неопределенное действие
	Rss -ab x
Tst 1:2 Дублирование действия
	Rss -aa x
Tst 1:2 Неверное задание даты
	Rss -D data -a x
Tst 1:2 Попытка работы с некорректной базой данных
	Sql "CREATE TABLE db (a)"
	Rss -a x
Tst 1:2 Сохранение объектa с некорректным именем
	Sql "DROP TABLE db"
	Rss -b .
Tst 0:1 Попытка сохранения несуществующего объекта
	Rss -b dir
Tst 1:2 Попытка сохранения с заданием имени объектa без указания исходника
	Rss -R dir/none -b
Tst 1:2 Попытка сохранения с заданием имени объектa и лишним аргументом
	Rss -R dir/none -b none none
Tst 1:2 Попытка сохранения с заданием некорректного имени объектa
	Rss -R " " -b Rss
Tst 0:1 Сохранение объекта по имени
	Rss -R dir/none -b Rss
Tst 0:1 Повторное сохранение объекта по имени
	Rss -R dir/none -b Rss
Tst 0:2 Получение информации о всех версиях объектов
	Rss -a \*
Tst 0:1 Сохранениe с заданием даты
	Rss -D " " -b Rss
Tst 0:2 Проверка содержимого базы данных
	Sql "SELECT d,t,p,i FROM db"
Tst 0:1 Повторное сохранениe с заданием даты
	Rss -D 0 -b Rss
Tst 0:2 Проверка содержимого базы данных
	Sql "SELECT d,t,p,i FROM db"
Tst 0:1 Повторное сохранениe объекта по имени с заданием даты
	Rss -R Rss -b dir/none
Tst 0:1 Удаление объекта
	Rss -en Rss
Tst 0:2 Получение информации о всех версиях объектов
	Rss -a \*
Tst 0:1 Сохранение объектов \(Version 1\)
	mkdir -p dir
	ln -sf none dir/link
	echo Version 1 >dir/file
	Chk >.inf
	Rss -b $LST
Tst 0:5 Получение списка измененных объектов
	V1=$(date)
	Rss -D "now - 5 minutes" -c \*
Tst 0:6 Получение информации о всех объектах
	Rss -a \*
Tst 0:4 Получение информации об активных объектах
	Rss -i \*
Tst 0:4 Восстановление измененных объектов
	echo >dir/file
	chmod 660 dir/file
	rm dir/link
	ln -sf file dir/link
	chmod 700 dir
	chgrp -R 0 dir
	Rss -nr \*
Tst 0:0 Проверка восстановления объектов
	Chk | diff -U0 .inf -
Tst 0:2 Восстановление файла вместо каталога
	rm dir/file
	mkdir dir/file
	Rss -nr dir/file
Tst 0:2 Восстановление файла вместо ссылки
	rm dir/file
	ln -sf bad dir/file
	Rss -nr dir/file
Tst 0:2 Восстановление ссылки вместо каталога
	rm dir/link
	mkdir dir/link
	Rss -nr dir/link
Tst 0:2 Восстановление ссылки вместо файла
	rm dir/link
	touch dir/link
	Rss -nr dir/link
Tst 0:2 Восстановление каталога вместо файла
	rm -rf dir
	touch dir
	Rss -nr dir
Tst 0:2 Восстановление каталога вместо ссылки
	rm -rf dir
	ln -s bad dir
	Rss -nr dir
Tst 0:4 Восстановление с нуля
	rm -rf dir
	Rss -nr dir\*
Tst 0:0 Проверка восстановления
	Chk | diff -U0 .inf -
Tst 1:2 Попытка получения последней версии файла на STDOUT без указания имени
	Rss -o
Tst 1:2 Попытка получения последней версии файла на STDOUT с лишним аргументом
	Rss -o dir/file x
Tst 0:1 Получение последней версии на STDOUT несуществующего объекта
	Rss -o x
Tst 0:1 Получениe последней версии объекта не являющимся файлом на STDOUT
	Rss -o dir/link
Tst 0:1 Получениe последней версии удаленного файла на STDOUT
	Rss -o dir/none
Tst 0:2 Получение последней версии файла на STDOUT
	Rss -o dir/file | tee .tmp
	sed '1d' .tmp | diff -u dir/file -
Tst 0:1 Сохранение объектов \(Version 2\)
	sleep 1
	V2=$(date +%s)
	mkdir -p dir
	chmod 770 dir
	ln -sf file dir/link
	echo Version 2 >dir/file
	chmod 640 dir/file
	Chk >.tmp
	Rss -b $LST
Tst 0:4 Восстановление на заданную дату
	Rss -D "$V1" -rn $LST
Tst 0:0 Проверка восстановления
	Chk | diff -U0 .inf -
Tst 0:4 Восстановление последних версий объектов
	Rss -rn dir\*
Tst 0:0 Проверка восстановления
	Chk | diff -U0 .tmp -
Tst 1:3 Попытка восстановления файла в каталоге закрытом для записи
	rm dir/file
	chmod 555 dir
	Rss -rn dir/file
Tst 0:2 Восстановлениe каталога закрытого для записи
	Rss -rn dir
Tst 0:4 Получение списка активных объектов
	Rss -l \*
Tst 0:9 Получение полной информации о всех версиях объектов
	Rss -a \*
Tst 1:2 Удаления всех, кроме последней, версий без указания имени объекта
	Rss -e
Tst 0:1 Удаление всех, кроме последней значимой, версий объектов
	Rss -e \*
Tst 0:5 Проверка базы данных
	Sql "SELECT d,t,p,i FROM db"
Tst 0:1 Удаление неактивного объекта из БД
	Rss -en dir/none
Tst 0:4 Получение информации о всех версиях объектов
	Rss -a \*
Tst 1:3 Попытка восстановления объекта с ошибкой в БД
	Sql "UPDATE db SET d='1970-01-01 00:00:00', b='aaaaa' WHERE rowid=2"
	Rss -D 0 -rn \*
Tst 1:2 Получение последней версии файла на STDOUT для записи с ошибкой в БД
	Rss -o dir/file
Tst 1:2 Обновление объекта для записи с ошибкой в БД
	touch dir/file
	Rss -b dir/file
Tst 0:0 Полная очистка БД для тестирования режима отчета
	rm -rf dir
	Sql "DELETE FROM db"
Tst 1:2 Попытка запуска Rss в режиме отчета без указания аргумента
	Rss -s
Tst 1:2 Попытка запуска Rss в режиме отчета для неисполняемого файла
	touch Rep
	Rss -s Rep
Tst 0:1 Попытка запуска Rss в режиме отчета для пустого каталога
	mkdir -p dir/rep
	Rss -s dir/rep
Tst 0:17 Подготовка тестовых отчетов в каталоге
	for N in 0 1 2 3; do
		echo "$ cat dir/rep/r$N"
		echo "#/bin/sh\necho Report $N" | tee dir/rep/r$N
	done
	chmod 755 dir/rep/r[1-3]
	echo \$ ls -al dir/rep/r\*
	ls -al dir/rep/r*
Tst 0:10 Запуск Rss в режиме отчета для каталога c примерами отчетов
	Rss -s dir/rep
Tst 0:16 Формирование тестового отчета с ошибками вызова
	cat <<-END >Rep
	Rss "$PWD/*"
	Rss "$PWD/./dir"
	Rss "$PWD/../dir"
	Rss "$PWD/d'ir"
	Rss "$PWD//dir"
	Rss "$PWD/ /dir"
	Rss WRK/dir/
	Rss "$PWD/dir/" +
	Rss "$PWD/dir/" + /a
	Rss "$PWD/dir/" + a/./
	Rss "$PWD/dir/" + ../b
	Rss "$PWD/dir/" + 'a b'
	Rss "$PWD/dir/" + a - b
	Rss "$PWD/dir" =
	Rss "$PWD/dir/rep/r0" = None
	END
	chmod 755 Rep
	echo "$ cat Rep"
	cat Rep
Tst 0:46 Запуск Rss в режиме отчета для тестового отчета с ошибками вызова
	Rss -s Rep
Tst 0:26 Формирование тестового отчета
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
Tst 0:34 Получение тестового отчета первый раз
	Rss -s Rep
Tst 0:25 Получение тестового отчета повторно
	sleep 1
	Rss -s Rep
Tst 0:18 Формирование тестового отчета работы с файлами
	mkdir -p dir
	echo >dir/file
	echo File 0 >dir/file0
	echo Version 1 >dir/file1
	{	echo "root::0::::::"
		echo "mail:x:0::::::"
	} >dir/file2
	{	echo Text
		echo Line
		echo Word
		echo End
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
	Rss "$PWD/dir/none"
	# Файл присутствует
	Rss "$PWD/dir/file"
	# Сравнение старой и новой версии не производится
	Rss "$PWD/dir/file0" = false
	# Нестандартный поиск отличий
	Rss "$PWD/dir/file2" = Diff
	# Другое свое сравнение
	Rss "$PWD/dir/file3" = Di
	END
	chmod 755 Rep
	echo "$ cat Rep"
	cat Rep
Tst 0:29 Получение тестового отчета работы с файлами первый раз
	Rss -s Rep
Tst 0:1 Получение тестового отчета работы с файлами повторно
	sleep 1
	Rss -s Rep
Tst 0:20 Получение тестового отчета работы с файлами после изменений
	rm dir/file
	echo Version 2 >dir/file1
	echo "nobody:xxx:0::::::" >>dir/file2
	echo Append >>dir/file3
	chmod 444 dir/file0
	chmod 600 dir/file2
	sleep 1
	Rss -s Rep
Tst 0:15 Формирование тестового отчета работы со списками файлов
	echo "$ find dir | sort | xargs ls -ald"
	find dir | sort | xargs ls -ald
	cat <<-END >Rep
	#!/bin/sh
	Rss $PWD/dir/ + rep = false  Различия не ищутся
	Rss $PWD/dir/ - rep
	END
	chmod 755 Rep
	echo "$ cat Rep"
	cat Rep
Tst 0:16 Получение тестового отчета работы со списком файлов
	sleep 1
	V3=$(date)
	Rss -s Rep
Tst 0:40 Внесение изменений в тестовые файлы и получение нового отчета
	echo New >dir/file
	echo Version 3 >dir/file1
	echo "user:aa:0::::::" >>dir/file2
	echo Clean >dir/file3
	sleep 1
	Rss -s Rep
Tst 0:1 Получение всех версий файлов
	Rss -R 0 -x \*/file\*
Tst 0:13 Список файлов
	echo \$ ls 0$PWD/dir
	ls 0$PWD/dir
Tst 0:1 Получение всех версий файлов старше даты
	Rss -R 1 -D "$V3" -x \*file\*
Tst 0:6 Список файлов
	echo \$ ls 1$PWD/dir
	ls 1$PWD/dir
Tst 0:0 Очищаем БД для тестирования удаления и вывода различий
	Sql "DELETE FROM db"
Tst 0:1 Первая версия файла
	echo 0 >a
	Rss -b a
Tst 0:1 Вторая версия файла
	F=$(Get a)
	D0=$(date)
	sleep 1
	echo 1 >a
	Rss -b a
Tst 0:1 Третья версия файла
	D1=$(date)
	sleep 1
	rm a
	Rss -b a
Tst 0:1 Четвертая версия файла
	D2=$(date)
	sleep 1
	echo 1 >a
	Rss -b a
Tst 0:1 Пятая версия файла
	sleep 1
	echo -1 >a
	Rss -b a
Tst 0:1 Шестая версия файла
	D3=$(date)
	sleep 1
	echo 1 >a
	Rss -b a
Tst 0:1 Седьмая версия файла
	sleep 1
	echo 2 >a
	Rss -b a
Tst 0:1 Восьмая версия файла
	cp .Rss .Rss.new	# сохраним для тестирования совместимости
	sleep 1
	echo 3 >a
	chmod 640 a
	chgrp root a
	Rss -b a
Tst 0:9 Проверяем количество объектов
	Rss -a \*
Tst 0:2 Восстанавливаем начальную версию файла
	Rss -D "$D0" -rn a
Tst 0:1 Проверяем восстановление
	C=$(Get a)
	echo "'$F' = '$C'"
	[ "$F" = "$C" ]
Tst 1:2 Удаляем несуществующий объект
	Rss -z b
Tst 0:6 Различия содержимого на заданную дату
	Rss -D "$D1" -d a
Tst 0:2 Удаляем самый старый файл
	Rss -D "$D0" -zn a
Tst 0:5 Различия содержимого на заданную дату
	Rss -D "$D1" -d a
Tst 0:2 Удаляем отметку удаления, где версии до и после удаления идентичны
	Rss -D "$D2" -zn a
Tst 0:6 Проверка наличия объектов в БД
	Rss -a a
Tst 0:2 Удаляем файл, где версии до и после него идентичны
	Rss -D "$D3" -zn a
Tst 0:4 Проверка наличия объектов в БД
	Rss -a a
Tst 0:6 Различия между предпоследней и последней версиями файла
	Rss -d a
Tst 0:2 Удаляем последнюю версию файла
	Rss -zn a
Tst 0:6 Различия между предпоследней и последней версиями файла
	Rss -d a
Tst 0:2 Оставляем единственный самый старый вариант
	Rss -zn a
Tst 0:5 Различия для единственного варианта
	Rss -d a
Tst 0:2 Окончательное удаление объекта
	Rss -zn a
Tst 0:1 Проверка на отсутствие объектов
	Rss -a \*
Tst 0:0 Формируем БД предыдущего формата
	cp .Rss.new .Rss
	Sql "UPDATE db SET i=rtrim(i,' 0123456789') WHERE t='-'"
Tst 0:1 Восьмая версия файла 
	sleep 1
	echo 3 >a
	chmod 640 a
	chgrp root a
	Rss -b a
Tst 0:9 Проверяем количество объектов
	Rss -a \*
Tst 0:2 Восстанавливаем начальное состояния файла
	Rss -D "$D0" -rn a
Tst 0:1 Проверяем восстановленный файл
	C=$(Get a)
	echo "'$F' = '$C'"
	[ "$F" = "$C" ]
Tst 1:2 Удаляем несуществующий объект
	Rss -z b
Tst 0:6 Различия содержимого на заданную дату
	Rss -D "$D1" -d a
Tst 0:2 Удаляем самый старый файл
	Rss -D "$D0" -zn a
Tst 0:5 Различия содержимого на заданную дату
	Rss -D "$D1" -d a
Tst 0:2 Удаляем отметку удаления, где версии до и после удаления идентичны
	Rss -D "$D2" -zn a
Tst 0:6 Проверка наличия объектов в БД
	Rss -a a
Tst 0:2 Удаляем файл, где версии до и после него идентичны
	Rss -D "$D3" -zn a
Tst 0:4 Проверка наличия объектов в БД
	Rss -a a
Tst 0:6 Различия между предпоследней и последней версиями файла
	Rss -d a
Tst 0:2 Удаляем последнюю версию файла
	Rss -zn a
Tst 0:6 Различия между предпоследней и последней версиями файла
	Rss -d a
Tst 0:2 Оставляем единственный самый старый вариант
	Rss -zn a
Tst 0:5 Различия для единственного варианта
	Rss -d a
Tst 0:2 Окончательное удаление объекта
	Rss -zn a
Tst 0:1 Проверка на отсутствие объектов
	Rss -a \*
