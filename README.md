picodata-ansible
=========

Роль для разворачивания кластера picodata

Требования
------------

Наличие подготовленных серверов с поддерживаемыми ОС (список см. https://picodata.io/download/) с необходимым количеством ресурсов из минимального расчета на 1 инстанс (без учета ресурсов для ОС): 1 CPU, 256 Mb RAM, 1Gb HDD

Переменные роли
--------------

Переменные по умолчанию располагаются в файле defaults/main.yml, эти переменные можно переопределять в инвентарном файле

Помимо переменных по умолчанию используется словарь replicasets с указанием внутри 
- имени репликасета (например router)
- количество инстансов на каждом сервере (instances_per_server)
- фактор репликации (replication_factor), по умолчанию 1 - пока эта переменная определяется на весь кластер и берется из первого инстанса

Пример:
```
replicasets:
  router:  # replicaset-id ???
    instances_per_server: 1 # How many replicasets we want, by default equal 1
    replication_factor: 2 # Number of instances in replicaset, default 1
  storage: # replicaset-id ???
    instances_per_server: 1 # How many replicasets we want, by default equal 1
    replication_factor: 3 # Number of instances in replicaset, default 1
```


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
    data_dir: '/var/lib/picodata'  # каталог для хранения данных
    run_dir: '/var/run/picodata'   # каталог для хранения sock-файлов
    log_dir: '/var/log/picodata'   # каталог для логов и файлов аудита

    purge: true   # при очистке кластера удалять в том числе все данные и логи с сервера

    first_port: 3301     # начальный порт для первого инстанса (он же main_peer)

    replicasets:                                                                        # описание репликасетов
      router:                                                                           # имя репликасета
        instances_per_server: 1                                                         # сколько инстансов запустить на каждом сервере
        replication_factor: 2                                                           # количество инстансов в одном репликасете, по умолчанию 1
                                                                                        # на данный момент для всех репликасетов используется 
                                                                                        # определение только из первого
      storage:                                                                        # имя репликасета
        instances_per_server: 1                                                       # сколько инстансов запустить на каждом сервере
        replication_factor: 1                                                         # количество инстансов в одном репликасете, по умолчанию 1
                                                                                      # на данный момент для всех репликасетов используется 
                                                                                      # определение только из первого, т.е. в данном случае 2, а не 1!

DC1:                                # Датацентр (failure_domain)
  hosts:                            # серверы в датацентре
    server-1-1:                     # имя сервера в инвентарном файле
      ansible_host: 192.168.19.21   # IP адрес или fqdn если не совпадает с предыдущей строкой

DC2: # failure_domain              # Датацентр (failure_domain)
  hosts:                           # серверы в датацентре
    server-2-1:                    # имя сервера в инвентарном файле
      ansible_host: 192.168.19.22  # IP адрес или fqdn если не совпадает с предыдущей строкой
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

Лицензия
-------

BSD
