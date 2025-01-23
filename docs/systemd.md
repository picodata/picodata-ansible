# Особенности настройки кластера в случае использования systemd 

В случае выбора системы управления процессами systemd вы можете произвести дополнительные настройки systemd-службы, например увеличить лимиты.

Настройки при этом будут применяться для каждого инстанса кластера.

## Настройка лимитов в инвентарном файле

По умолчанию для systemd-службы выставлены следующие параметры:
```
  LimitNOFILE: 65535        # Increase fd limit for Vinyl
  LimitCORE: infinity       # Unlimited coredump filesize
  TimeoutStartSec: 86400s   # Systemd waits until all xlogs are recovered
  TimeoutStopSec: 20s       # Give a reasonable amount of time to close xlogs
```

Вы можете переопределить их в инвентарном файле через словарь `systemd_params`, либо в этом же словаре выставить любые другие параметры, которые используются в systemd-юнитах.

Пример фрагмента инвентарного файла с определнием словаря `systemd_params`:
```
all:
  vars:
    systemd_params:
      LimitNOFILE: 900000
      TimeoutStartSec: '30m'
```

## Системные ограничения

Некоторые параметры не могут иметь значение выше установленного в операционной системе, поэтому для их выставления предварительно нужно увеличить системные через `sysctl` или `limits.conf`. 

Например, параметр `LimitNOFILE` не может превышать системное значение `fs.nr_open` - если вы хотите выставить большее значение, то предварительно нужно изменить значение в системе:

Узнать текущее значение:
```bash
sysctl fs.nr_open
```

Отредактируйте файл `/etc/sysctl.conf` (при отсутствии создайте его), выставив в нем увеличенное значение параметра `fs.nr_open`:
```bash
sudo vi /etc/sysctl.conf
fs.nr_open=999999
```

Примените измененные значения:
```bash
sudo sysctl -p
```

Подробнее про лимиты читайте в документации:

- [The Linux Kernel Documentation](https://www.kernel.org/doc/Documentation/sysctl/)

- `systemd.exec` manpage

## Проверка лимитов

Лимиты, выставленные для процесса можно получить командой:
```bash
cat /proc/<MainPID>/limits
```

Значение `MainPID` вы можете получить из вывода команды `systemctl show --property=MainPID  <имя службы инстанса picodata>`
