# picodata-ansible

Роль для разворачивания кластера picodata

## Требования


Наличие подготовленных серверов с поддерживаемыми ОС (список см. https://picodata.io/download/) с необходимым количеством ресурсов из минимального расчета на 1 инстанс (без учета ресурсов для ОС): 1 CPU, 64 Mb RAM, 512Mb HDD

## Переменные роли

> **Внимание!**

> **Все переменные и настройки из конфигурационного файла используются только один раз при первоначальном поднятии кластера!!!**

> **В дальнейшем, на данный момент, изменить эти настройки можно только через lua!!!**

---

Переменные по умолчанию располагаются в файле `defaults/main.yml`, эти переменные можно переопределять в инвентарном файле

Помимо переменных по умолчанию используется словарь tiers с указанием внутри 
- имени тира (например `router`)
- количество инстансов на каждом сервере (`instances_per_server`)
- фактор репликации (`replication_factor`) для тира, по умолчанию 1
- параметров запуска box.cfg инстансов тира (`tnt_params`)

Пример словаря tiers:
```
tiers:
  default:                     # имя тира default
    instances_per_server: 2    # сколько инстансов запустить на каждом сервере
    replication_factor: 3      # фактор репликации
    config:
      memtx:
        memory: 73400320               # количество памяти, предоставляемое непосредственно на хранение данных в байтах
        checkpoint_interval: 7200      # период активности службы создания снапшотов (checkpoint daemon) в секундах
        checkpoint_count: 3            # максимальное количество снапшотов, хранящихся в директории data_dir
      iproto:
        max_concurrent_messages: 1024  # максимальное количество сообщений, которое Picodata обрабатывает параллельно
```

Полное описание всех переменных роли см. в [docs/variables.md](docs/variables.md)

## Зависимости

Пока нет


## Использование роли

Вы можете инсталлировать роль через ansible-galaxy:


```bash
ansible-galaxy install git+https://git.picodata.io/picodata/picodata/picodata-ansible.git
```

или добавить ее в файл requirements.yml:

```yml
- src: https://git.picodata.io/picodata/picodata/picodata-ansible.git
  scm: git
```

и затем выполнить команду
```bash
ansible-galaxy install -fr requirements.yml
```

## Примеры
----------------

### Инвентарный файл

Пример инвентарного файла для 3-х серверов, расположенных в 3 дата центрах DC1, DC2 и DC3, имя файла `hosts.yml`
```yml
all:
  vars:
    ansible_user: vagrant      # пользователь для ssh-доступа к серверам           

    repo: 'https://download.picodata.io'  # репозиторий, откуда инсталлировать пакет picodata

    cluster_id: test               # имя кластера
    audit: false                   # отключение айдита
    log_level: info                # уровень отладки
    log_to: file                   # вывод логов в файлы, а не в journald

    conf_dir: '/etc/picodata'      # каталог для хранения конфигурационных файлов
    data_dir: '/var/lib/picodata'  # каталог для хранения данных
    run_dir: '/var/run/picodata'   # каталог для хранения sock-файлов
    log_dir: '/var/log/picodata'   # каталог для логов и файлов аудита

    purge: true   # при очистке кластера удалять в том числе все данные и логи с сервера

    listen_address: '{{ ansible_fqdn }}'     # адрес, который будет слушать инстанс, по умолчанию ansible_fqdn

    first_bin_port: 13301     # начальный бинарный порт для первого инстанса (он же main_peer)
    first_http_port: 18001    # начальный http-порт для первого инстанса для веб-интерфейса
    first_pg_port: 15001      # начальный номер порта для postgress-протокола инстансов кластера

    tiers:                         # описание тиров (тиры пока нигде не используются, поэтому нет смсыла сосздавать дополнительные тиры)
      default:                     # имя тира default
        instances_per_server: 2    # сколько инстансов запустить на каждом сервере
        replication_factor: 3      # фактор репликации
        config:
          memtx:
            memory: 73400320               # количество памяти, предоставляемое непосредственно на хранение данных в байтах
            checkpoint_interval: 7200      # период активности службы создания снапшотов (checkpoint daemon) в секундах
            checkpoint_count: 3            # максимальное количество снапшотов, хранящихся в директории data_dir
          iproto:
            max_concurrent_messages: 1024  # максимальное количество сообщений, которое Picodata обрабатывает параллельно


DC1:                               # Датацентр (failure_domain)
  hosts:                           # серверы в датацентре
    server-1-1:                    # имя сервера в инвентарном файле
      ansible_host: 192.168.19.21  # IP адрес или fqdn если не совпадает с предыдущей строкой

DC2:                               # Датацентр (failure_domain)
  hosts:                           # серверы в датацентре
    server-2-1:                    # имя сервера в инвентарном файле
      ansible_host: 192.168.19.22  # IP адрес или fqdn если не совпадает с предыдущей строкой

DC3:                               # Датацентр (failure_domain)
  hosts:                           # серверы в датацентре
    server-3-1:                    # имя сервера в инвентарном файле
      ansible_host: 192.168.19.23  # IP адрес или fqdn если не совпадает с предыдущей строкой
```

## Плэйбук

Пример плэйбука `run.yml`:
```yml
---
- name: Deploy picodata cluster
  hosts: all
  become: true

  tasks:

  - name: Import picodata-ansible role
    ansible.builtin.import_role:
      name: picodata-ansible
```

## Примеры команд запуска роли

Пример команды для установки кластера:
```bash
ansible-playbook -i hosts.yml run.yml
```

---

Пример команды для удаления кластера:
```bash
ansible-playbook -i hosts.yml run.yml -t remove
```

> Если при запуске будет выставлена переменная `purge`, то кластер удалится вместе с данными.

```bash
ansible-playbook -i hosts.yml run.yml -t remove -e purge=true
```


---

Пример команды для бэкапа кластера:
```bash
ansible-playbook -i hosts.yml run.yml -t backup
```

---

Пример команды для восстановления кластера:
```bash
ansible-playbook -i hosts.yml run.yml -t restore
```

Полное описание всех тэгов роли см. в [docs/tags.md](docs/tags.md)


## Лицензия

BSD
