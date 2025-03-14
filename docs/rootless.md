# Инсталляция кластера на серверах с разграничением полномочий

В крупных организациях роли системного администратора (Администратора ОС) и Администратора БД разделены с целью обеспечения информационной безопасности.
В этом случае роль позволяет выполнить первоначальную настройку серверов с учетной записью Администратора ОС и последующую инсталляцию кластера Администратором БД (при выборе системы управления процессами `supervisord`).

> Независимо от варианта инсталляции кластера процессы инстансов на серверах могут быть запущены под сервисной учетной записью (см. параметры `user` и `group`)


## Требования для установки кластера

> Для удобства администрирования кластера корневые каталоги желательно (но не обязательно) располагать в отдельном разделе (`/opt`, `/data`, `/app`).

На серверах кластера должны быть выполнены действия:
- установлен пакет `picodata` необходимой версии
- создана учетная записи для Администратора ОС (с полными sudo-полномочиями без запроса пароля)
- создана учетная записи для Администратора БД
- создана учетная записи для пользователя, указанного в параметре `user` (при необходимости)

> Параметры учетной записи, указанной в параметре `user`:
```
create_home=yes
shell=/sbin/nologin
```

В инвентарном файле:
- при необходимости определить каталоги: `conf_dir`, `data_dir`, `run_dir`, `log_dir`
- выставить значение переменной `rootless` в `true`

### Для системы управления процессами supervisord

На серверах:
- должна присутствовать утилита `setfacl` (обычно находится в пакете `acl`)
- установлен пакет `supervisor`

В инвентарном файле:
- при необходимости определить каталоги: `supervisord_dir`
- выставить значение переменной `init_system` в `supervisord`
- имя пользователя (переменная `user`) должно совпадать с учетной записью Администратора БД, под которой планируется управлять кластером -  это техническое ограничение на данный момент

## Система управления процессами supervisord

При выборе данной системы управления процессами пользователю будет предоставлено больше полномочий, чем при выборе системы `systemd`:

- Администратор ОС выполняет шаги для первоначальной настройки серверов, дальнейшая раскатка кластера возможна Администратором БД
- добавление инстансов в кластер Администратором БД (без привлечения Администратора ОС)
- возможность восстановления из бэкапов (сами бэкапы можно будет делать при любой системе управления процессами)

### Первоначальная настройка серверов

Выполняется под учетной записью Администратора ОС, например `sysadm`, у данной учетной записи должна быть возможность повышения привилегий через `sudo` без запроса пароля (`NOPASSWD`).

Первоначальная настройка серверов состоит из шагов:
- при отсутствии на серверах пакета `picodata` подключается репозиторий Пикодаты и из него устанавливается пакет `picodata` последней доступной версии
- создаются каталоги для работы `picodata`
- создается systemd служба для `supervisord`
- при размещении логов в файлах, создается logrotate-файл для их подрезки

> Здесь и далее в примерах плейбук `picodata.yml` взят из файла [README.md](../README.md)
> При этом необходимо выставить значение параметра `become` в `false`

```yaml
---
- name: Deploy picodata cluster
  hosts: all
  become: false

  tasks:

  - name: Import picodata-ansible role
    ansible.builtin.import_role:
      name: picodata-ansible
```

Подготовка серверов кластера выполняется командой:
```bash
ansible-playbook -i <inventory> picodata.yml -t deploy_become -e 'ansible_user=sysadm' -e 'ansible_password=<verysecret>'
```

### Инсталляция кластера

Выполняется под учетной записью Администратора БД, например `dbadm`.

Установка кластера выполняется командой:
```bash
ansible-playbook -i <inventory> picodata.yml -e 'ansible_user=dbadm' -e 'ansible_password=<verysecret>'
```

При этом задачи, требующие повышенных привилегий будут пропущены.

> Переменные `ansible_user` и `ansible_password` можно вынести в переменные окружения, либо в файл `ansible.cfg` - в таком случае указывать их при запуске команды будет не нужно.
Как это сделать описано в [документации Ansible](https://docs.ansible.com/ansible/latest/reference_appendices/config.html).
>
> Наша рекомендация - использовать доступ к серверам по ssh-ключу вместо пароля.

### Работа с кластером через supervisord

Администратор БД может выполнять различные команды для управления процессами инстансов на серверах кластера, например:

```bash
supervisorctl -c /data/picodata/supervisord/test.conf status
supervisorctl -c /data/picodata/supervisord/test.conf restart default-1000
supervisorctl -c /data/picodata/supervisord/test.conf signal HUP router-1001
supervisorctl -c /data/picodata/supervisord/test.conf stop all
```

Где:
- `supervisor_dir` = `/data/picodata/supervisord`
- `cluster_name` = `test`
- `default-1000`, `router-1001` - названия инстансов

Для удобства администратотра можно установить альяс в shell-оболочке:
```bash
picosuper='supervisorctl -c /data/picodata/supervisord/test.conf'
```

и в дальнейшем использовать его при вызове команд:
```bash
picosuper status
picosuper restart default-1000
picosuper signal HUP router-1001
picosuper stop all
```


### Удаление кластера

Удаление кластера выполняется в обратном порядке: сначала под учетной записью Администратора БД останавливаем кластер и удаляем данные, затем, при необходимости, под Администратором ОС удаляем системные файлы и каталоги.

> Подразумевается, что переменная `ansible_user` для Администратора БД прописана в инвентарном файле.

Удаление кластера выполняется командой:
```bash
ansible-playbook -i <inventory> picodata.yml -t remove
```

### Очистка серверов от системных файлов кластера

Выполняется под учетной записью Администратора ОС, например `sysadm`.

Очистка серверов выполняется командой:
```bash
ansible-playbook -i <inventory> picodata.yml -t remove_become -e 'ansible_user=sysadm' -e 'ansible_password=<verysecret>'
```

При этом будет остановлена и удалена systemd-служба запуска `supervisord`, удалены все корневые каталоги, которые были созданы для кластера.

---

## Система управления процессами systemd

При выборе данной системы управления процессами пользователю накладываются ограничения:
- установка кластера выполняется Администратором ОС
- добавление инстансов возможно только Администратором ОС
- восстановление из бэкапа возможно только Администратором ОС (сами бэкапы можно будет делать при любой системе управления процессами)

### Инсталляция кластера

Выполняется под учетной записью Администратора ОС, например `sysadm`.

> Здесь и далее в примерах плейбук `picodata.yml` взят из файла [README.md](../README.md)
```yaml
---
- name: Deploy picodata cluster
  hosts: all
  become: true

  tasks:

  - name: Import picodata-ansible role
    ansible.builtin.import_role:
      name: picodata-ansible
```

Установка кластера выполняется командой:
```bash
ansible-playbook -i <inventory> picodata.yml -e 'ansible_user=sysadm' -e 'ansible_password=<verysecret>'
```

> Переменные `ansible_user` и `ansible_password` желательно указать в инвентарном файле. Наша рекомендация - использовать доступ к серверам по ssh-ключу вместо пароля.

### Работа с кластером в пользовательском пространстве systemd

Администратор БД может работать с процессами инстансов при переключении на пользователя, указанного в параметре `user`
> Администратору ОС необходимо настроить возможность переключения на данного пользователя через sudo из учетной записи Администратора БД, пример вызова команды: `sudo -su picodata`)
>
> После переключения на пользователя `user` для работы `systemctl` потребуется выставить переменную окружения `XDG_RUNTIME_DIR` командой:
```bash
export XDG_RUNTIME_DIR=/run/user/$(id -u)
```

Примеры команд (выполнять без sudo!!!):
```bash
systemctl --user status test@*
systemctl --user restart test@default-1000
systemctl --user -s HUP kill test@router-1001
systemctl --user stop test@*
```

Где:
- `cluster_name` = `test`
- `default-1000`, `router-1001` - названия инстансов

### Удаление кластера

Удаление кластера выполняется Администратором ОС.

> Подразумевается, что переменная `ansible_user` прописана в инвентарном файле.

Удаление кластера выполняется командой:
```bash
ansible-playbook -i <inventory> picodata.yml -t remove
```
