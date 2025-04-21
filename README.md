# picodata-ansible

Роль для разворачивания кластера picodata

## Требования

Наличие подготовленных серверов с поддерживаемыми ОС (список см. https://picodata.io/download/) с необходимым количеством ресурсов из минимального расчета на 1 инстанс (без учета ресурсов для ОС): 1 CPU, 64 Mb RAM, 512Mb HDD

## Переменные роли

Переменные по умолчанию располагаются в файле `defaults/main.yml`, эти переменные можно переопределять в инвентарном файле

Помимо переменных по умолчанию используется словарь tiers с указанием внутри 
- имени тира (например `router`)
- количество репликасетов (`replicaset_count`) или количество инстансов на каждом сервере (`instances_per_server`)
- фактора репликации (`replication_factor`) для тира, по умолчанию 1

Пример словаря tiers:
```
tiers:
  default:                     # имя тира default
    replicaset_count: 2        # количество репликасетов
    replication_factor: 3      # фактор репликации
    bucket_count: 16384        # количество бакетов в тире
    config:
      memtx:
        memory: 128M           # количество памяти, предоставляемое непосредственно на хранение данных
```

Полное описание всех переменных роли см. в [docs/variables.md](docs/variables.md)

## Зависимости

Пока нет


## Использование роли

Вы можете инсталлировать роль через ansible-galaxy:


```bash
ansible-galaxy install git+https://git.picodata.io/core/picodata-ansible.git
```

или добавить ее в файл requirements.yml:

```yml
- src: https://git.picodata.io/core/picodata-ansible.git
  scm: git
```

и затем выполнить команду
```bash
ansible-galaxy install -fr requirements.yml
```

## Примеры
----------------

### Инвентарный файл

Пример инвентарного файла для 4-х серверов, расположенных в 3 датацентрах DC1, DC2 и DC3, имя файла `hosts.yml`
```yml
all:
  vars:
    ansible_user: vagrant      # пользователь для ssh-доступа к серверам           

    repo: 'https://download.picodata.io'  # репозиторий, откуда инсталлировать пакет picodata

    cluster_name: 'demo'           # имя кластера
    admin_password: '123asdZXV'    # пароль пользователя admin

    default_bucket_count: 23100    # количество бакетов в каждом тире (по умолчанию 30000)

    audit: false                   # отключение айдита
    log_level: 'info'              # уровень отладки
    log_to: 'file'                 # вывод логов в файлы, а не в journald

    conf_dir: '/etc/picodata'         # каталог для хранения конфигурационных файлов
    data_dir: '/var/lib/picodata'     # каталог для хранения данных
    run_dir: '/var/run/picodata'      # каталог для хранения sock-файлов
    log_dir: '/var/log/picodata'      # каталог для логов и файлов аудита
    share_dir: '/usr/share/picodata'  # каталог для хранения размещения служебных данных (плагинов)

    listen_address: '{{ ansible_fqdn }}'     # адрес, который будет слушать инстанс

    first_bin_port: 13301     # начальный бинарный порт для первого инстанса
    first_http_port: 18001    # начальный http-порт для первого инстанса для веб-интерфейса
    first_pg_port: 15001      # начальный номер порта для postgress-протокола инстансов кластера

    tiers:                         # описание тиров
      arbiter:                     # имя тира
        replicaset_count: 1        # количество репликасетов
        replication_factor: 1      # фактор репликации
        config:
          memtx:
            memory: 64M            # количество памяти, выделяемое каждому инстансу тира
        host_groups:
          - ARBITERS               # целевая группа серверов для установки инстанса

      default:                     # имя тира
        replicaset_count: 3        # количество репликасетов
        replication_factor: 3      # фактор репликации
        bucket_count: 16384        # количество бакетов в тире
        config:
          memtx:
            memory: 71M            # количество памяти, выделяемое каждому инстансу тира
        host_groups:
          - STORAGES               # целевая группа серверов для установки инстанса

    db_config:                     # параметры конфигурации кластера https://docs.picodata.io/picodata/stable/reference/db_config/
      governor_auto_offline_timeout: 30
      iproto_net_msg_max: 500
      memtx_checkpoint_count: 1
      memtx_checkpoint_interval: 7200

    plugins:
      example:                                                  # плагин
        path: '../plugins/weather_0.1.0-ubuntu-focal.tar.gz'    # путь до пакета плагина
        config: '../plugins/weather-config.yml'                 # путь до файла с настройками плагина
        tiers:                                                  # список тиров, в которые плагин установливается
          - default

DC1:                                # Датацентр (failure_domain)
  hosts:                            # серверы в датацентре
    server-1-1:                     # имя сервера в инвентарном файле
      ansible_host: '192.168.19.21' # IP адрес или fqdn если не совпадает с предыдущей строкой
      host_group: 'STORAGES'        # определение целевой группы серверов для установки инстансов

    server-1-2:                     # имя сервера в инвентарном файле
      ansible_host: '192.168.19.22' # IP адрес или fqdn если не совпадает с предыдущей строкой
      host_group: 'ARBITERS'        # определение целевой группы серверов для установки инстансов

DC2:                                # Датацентр (failure_domain)
  hosts:                            # серверы в датацентре
    server-2-1:                     # имя сервера в инвентарном файле
      ansible_host: '192.168.20.21' # IP адрес или fqdn если не совпадает с предыдущей строкой
      host_group: 'STORAGES'        # определение целевой группы серверов для установки инстансов

DC3:                                # Датацентр (failure_domain)
  hosts:                            # серверы в датацентре
    server-3-1:                     # имя сервера в инвентарном файле
      ansible_host: '192.168.21.21' # IP адрес или fqdn если не совпадает с предыдущей строкой
      host_group: 'STORAGES'        # определение целевой группы серверов для установки инстансов
```

### Формулы для расчета количества инстансов/репликасетов

> В инвентарном файле для тиров можно указывать, как количество репликасетов, так и количество инстансов на каждом сервере, при этом в первом случае значение `instances_per_server` будет рассчитано автоматически. Если при расчете будет получено дробное значение, то роль остановится с ошибкой.

> Если указано оба параметра, то приоритет у `instances_per_server`

#### Количество репликасетов в кластере
```
replicaset_count = instances_per_server * SERVER_COUNT / replication_factor
```

> Если при расчете вы получаете дробное число, значит некорректно подобрано количество серверов или фактор репликации, это необходимо исправить

#### Необходимое количество инстансов на одном сервере
```
instances_per_server = replicaset_count * replication_factor / SERVER_COUNT
```

> Если при расчете вы получаете дробное число, значит некорректно подобрано количество серверов или фактор репликации, это необходимо исправить


## Плейбук

Пример плейбука `picodata.yml`:
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
ansible-playbook -i hosts.yml picodata.yml
```

> При успешном окончании выполнения плейбука будет создан yaml-файл `report.yml` с перечислением всех инстансов и портов кластера

---

Пример команды для удаления кластера:
```bash
ansible-playbook -i hosts.yml picodata.yml -t remove
```

---

Пример команды для бэкапа кластера:
```bash
ansible-playbook -i hosts.yml picodata.yml -t backup
```

---

Пример команды для восстановления кластера:
```bash
ansible-playbook -i hosts.yml picodata.yml -t restore
```

Полное описание всех тэгов роли см. в [docs/tags.md](docs/tags.md)


## Лицензия

BSD-2
