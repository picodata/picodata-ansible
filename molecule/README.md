# Образы для molecule

Джобы `molecule` и `manual` в `.gitlab-ci.yml` запускаются в образах с ansible и molecule:

| Образ | Dockerfile | Зависимости |
|---|---|---|
| `docker-picodata.binary.picodata.io/ansible-proxmox:latest` | `Dockerfile` | `requirements.yml` (ansible-core 2.16) |
| `docker-picodata.binary.picodata.io/ansible-proxmox:2.20` | `Dockerfile.ansible-2.20` | `requirements.ansible-2.20.yml` (ansible-core 2.20) |

CI эти образы не собирает. Их собирают и выкладывают вручную:

- после изменения Dockerfile или файла зависимостей, когда изменение попало в `main`;
- если джобы падают с `runner_configuration_error` и в логе есть
  `failed to pull image "docker-picodata.binary.picodata.io/ansible-proxmox:...": not found`.

Теги `latest` и `2.20` общие для всех веток. Собирайте из `main`, иначе остальные ветки получат образ из вашей ветки.

## Сборка и публикация

Нужны Docker и учётная запись с правом записи в `docker-picodata.binary.picodata.io`.

```bash
docker login docker-picodata.binary.picodata.io

git switch main && git pull
cd molecule

docker build --pull -t docker-picodata.binary.picodata.io/ansible-proxmox:latest -f Dockerfile .
docker build --pull -t docker-picodata.binary.picodata.io/ansible-proxmox:2.20 -f Dockerfile.ansible-2.20 .
```

Перед публикацией проверьте версии внутри образов:

```bash
for t in latest 2.20; do
  docker run --rm docker-picodata.binary.picodata.io/ansible-proxmox:$t sh -c 'ansible --version | head -1; molecule --version | head -1'
done
```

Опубликуйте образы:

```bash
docker push docker-picodata.binary.picodata.io/ansible-proxmox:latest
docker push docker-picodata.binary.picodata.io/ansible-proxmox:2.20
```
