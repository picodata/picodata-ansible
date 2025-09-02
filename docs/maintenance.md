# Обслуживание кластера

## Установка кластера

Пример команды:
```bash
ansible-playbook -i hosts.yml picodata.yml
```

> При успешном окончании выполнения плейбука будет создан yaml-файл `report.yml` с перечислением всех инстансов и портов кластера

---

## Удаление кластера

Пример команды:
```bash
ansible-playbook -i hosts.yml picodata.yml -t remove
```

---

## Работа с бэкапами

Пример команды для бэкапа кластера:
```bash
ansible-playbook -i hosts.yml picodata.yml -t backup
```

---

Пример команды для восстановления кластера в случае, если кластер уже развернут:
```bash
ansible-playbook -i hosts.yml picodata.yml -t restore
```

---

Пример команды для восстановления кластера на пустых серверах (будет развернут кластер и выполенено восстановление из последнего бэкапа):
```bash
ansible-playbook -i hosts.yml picodata.yml -t restore_full
```

---

Пример команды для восстановления кластера из определенного бэкапа:
```bash
ansible-playbook -i hosts.yml picodata.yml -t restore -e restore_dir=20250716203059
```

> Внимание! Восстановление из последнего бэкапа работает только при выставленной переменной `backup_fetch` в `true` (т.е. когда бэкапы выкачиваются на станцию запуска ansible), в остальных случаях необходимо указывать переменную `restore_dir`!

---
## Перезапуск инстансов кластера

Пример команды для перезапуска всех инстансов кластера:
```bash
ansible-playbook -i hosts.yml picodata.yml -t restart
```

---

## Остановка инстансов кластера

> Например для проведения работ на серверах

Пример команды для остановки всего кластера:
```bash
ansible-playbook -i hosts.yml picodata.yml -t stop
```

Пример команды для остановки всего кластера с отключением systemd служб (службы не будут запускаться автоматически после перезагрузки сервера):
```bash
ansible-playbook -i hosts.yml picodata.yml -t stop -e enable=false
```

---

Пример команды для остановки инстансов на определенном сервере с именем `host` (из указывается из инвентарного файла):
```bash
ansible-playbook -i hosts.yml picodata.yml -t stop -l host
```

---

Пример команды для остановки инстансов на определенном сервере с именем `host` (из указывается из инвентарного файла) с отключением автоматического запуска после рестарта сервера (только для systemd):
```bash
ansible-playbook -i hosts.yml picodata.yml -t stop -e enable=false -l host
```

---

## Запуск инстансов кластера

> Как правило, выполняется после остановки инстансов

Пример команды для запуска всех инстансов кластера:
```bash
ansible-playbook -i hosts.yml picodata.yml -t start
```

---

Пример команды для запуска инстансов на определенном сервере с именем `host` (из указывается из инвентарного файла):
```bash
ansible-playbook -i hosts.yml picodata.yml -t start -l host
```

---

## Работа с плагинами

Пример команды для установки плагинов, указанных в инвентарном файле:
```bash
ansible-playbook -i hosts.yml picodata.yml -t plugins
```

---

## Действия при авариях

Пример команды для сбора информации после сбоя кластера для отправки ее в техподдержку Пикодаты:
```bash
ansible-playbook -i hosts.yml picodata.yml -t crash_dump
```

Будет собрана вся информация для расследования инцидента. 
После выполнения передать файлы **"*_crash_dump_??????????????.tar.gz"** из каталога `backup_fetch_dir/cluster_name/` (`backup_fetch_dir` и `cluster_name` - переменные из инвентарного файла, если не определены, то используются значения по умолчанию) в техническую поддержку Пикодаты любым доступным способом

> Внимание! В случае проблем с выкачиванием файлов на хост с ansible, файлы будут сохранены в каталоге `backup_dir` на каждом сервере, их можно скачать вручную

> Внимание! На серверах и на станции ansible должно быть достаточно свободного места в разделах, где будут сформированы архивы `crash_dump`

Пример команды для сбора информации **без snap и xlog файлов** после сбоя кластера для отправки ее в техподдержку Пикодаты:
```bash
ansible-playbook -i hosts.yml picodata.yml -t crash_dump -e skipdata=true
```

---

## Прочее

Пример команды для установки пакета `picodata` (если не указана переменная `picodata_package_path`, то на серверах будет подключен репозиторий `picodata`):
```bash
ansible-playbook -i hosts.yml picodata.yml -t install_pkgs
```

Пример команды для получения информации об именах инстансов кластера с их привязкой к серверам:
```bash
ansible-playbook -i hosts.yml picodata.yml -t genin
```

Пример команды для выполнения lua-команды на всех инстансах кластера:
```bash
ansible-playbook -i hosts.yml picodata.yml -t command -e "cmdline='box.slab.info()'"
```

Пример команды для выполнения файла с набором lua-команд на всех инстансах кластера:
```bash
ansible-playbook -i hosts.yml picodata.yml -t command -e "cmdfile='../cmdfile.lua'"
```

Пример команды для выполнения lua-команды на инстансах кластера с именем `default`:
```bash
ansible-playbook -i hosts.yml picodata.yml -t command -e "cmdline='box.slab.info()'" -e "filter='default'"
```

Пример команды для выполнения lua-команды на инстансах кластера, отфильтрованных по условию с использованием регулярного выражения:
```bash
ansible-playbook -i hosts.yml picodata.yml -t command -e "cmdline='box.slab.info()'" -e "filter='.*-2[0-9]{3}'"
```

> Результат выполнения команд будет записан в файл `command_result_??????????????.log` в каталоге, определенном переменной `report_dir`
