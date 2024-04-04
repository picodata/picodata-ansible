picodata-ansible
=========

Роль для разворачивания кластера picodata

Требования
------------

Наличие подготовленных серверов с поддерживаемыми ОС (список см. https://picodata.io/download/) с необходимым количеством ресурсов из минимального расчета на 1 инстанс (без учета ресурсов для ОС): 1 CPU, 256 Mb RAM, 1Gb HDD

Переменные роли
--------------

Переменные по умолчанию располагаются в файле defaults/main.yml, эти переменные можно переопределять в инвентарном файле

Помимо переменных по умолчанию используется словарь tiers с указанием внутри 
- имени тира (например `router`)
- количество инстансов на каждом сервере (`instances_per_server`)
- фактор репликации (`replication_factor`) для тира, по умолчанию 1
- параметров запуска box.cfg инстансов тира (`tnt_params`)

Выполните роль с указанием переменной `force_remove` для удаления кластера.
Если дополнительно будет выставлена переменная `purge`, то кластер удалится вместе с данными.

Пример:
```
tiers:                              # описание тиров
  router:                           # имя тира router
    instances_per_server: 2         # сколько инстансов запустить на каждом сервере
    replication_factor: 1           # количество инстансов в одном репликасете, по умолчанию 1
    memtx_memory: '96M'             # размер памяти в human-формате, выделяемый инстансу в тире, по умолчанию 64M

  storage:                          # имя тира storage
    instances_per_server: 1         # сколько инстансов запустить на каждом сервере
    replication_factor: 2           # количество инстансов в одном репликасете, по умолчанию 1
    memtx_memory: '256M'            # размер памяти в human-формате, выделяемый инстансу в тире, по умолчанию 64M
    tnt_params:                     # параметры для ядра (box.cfg), выставляются на весь тир
      checkpoint_interval: 7200     # интервал для создания снэпшотов
```

Полное описание всех переменных роли см. в [docs/variables.md](docs/variables.md)

Зависимости
------------

Пока нет

Примеры
----------------

Пример инвентарного файла для 2-х серверов, расположенных в 2 дата центрах DC1 и DC2
```
all:
  vars:
    ansible_user: vagrant      # пользователь для ssh-доступа к серверам           

    install_packages: false               # отключение необходимости установки пакета picodata
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

    listen_ip: '{{ ansible_eth1.ipv4.address }}'     # ip-адрес, который будет слушать инстанс, по умолчанию ansible_default_ipv4.address

    first_bin_port: 13301     # начальный бинарный порт для первого инстанса (он же main_peer)
    first_http_port: 18001    # начальный http-порт для первого инстанса для веб-интерфейса

    tiers:                         # описание тиров (тиры пока нигде не используются, поэтому нет смсыла сосздавать дополнительные тиры)
      default:                     # имя тира default
        instances_per_server: 2    # сколько инстансов запустить на каждом сервере
        replication_factor: 3      # фактор репликации
        memtx_memory: 96M          # количество памяти, предоставляемое непосредственно на хранение данных

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

Пример роли:
```
---
- name: Deploy picodata cluster
  hosts: all
  become: true

  tasks:

  - name: Import picodata-ansible role
    ansible.builtin.import_role:
      name: picodata-ansible
```

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


Лицензия
-------

BSD
