# GitHub Workflows Repository Setup

## Crear repositorio: `labjp-xyz/github-workflows`

Este repositorio contendrá workflows reutilizables para todos tus proyectos.

### Estructura del repositorio github-workflows:

```
github-workflows/
├── .github/
│   └── workflows/
│       ├── docker-build-push.yml      # Construcción de imágenes Docker
│       ├── deploy-podman.yml          # Deployment con Podman
│       ├── security-scan.yml          # Escaneo de seguridad
│       └── n8n-deploy.yml            # Deployment específico de n8n
└── README.md
```

### Archivo: `.github/workflows/n8n-deploy.yml`

```yaml
name: n8n Deployment Workflow

on:
  workflow_call:
    inputs:
      environment:
        description: 'Target environment'
        required: false
        default: 'production'
        type: string
      image-tag:
        description: 'Image tag to deploy'
        required: false
        default: 'latest'
        type: string
      runner-label:
        description: 'Runner label to use'
        required: false
        default: 'self-hosted'
        type: string
    secrets:
      registry-username:
        required: false
      registry-password:
        required: false

jobs:
  deploy:
    name: Deploy n8n
    runs-on: ${{ inputs.runner-label }}
    environment: ${{ inputs.environment }}

    steps:
      # ... pasos de deployment ...
```

### Archivo: `.github/workflows/docker-build-push.yml`

```yaml
name: Docker Build and Push

on:
  workflow_call:
    inputs:
      registry:
        description: 'Container registry'
        required: false
        default: 'ghcr.io'
        type: string
      image-name:
        description: 'Image name'
        required: true
        type: string
      dockerfile:
        description: 'Path to Dockerfile'
        required: false
        default: './Dockerfile'
        type: string
      platforms:
        description: 'Target platforms'
        required: false
        default: 'linux/amd64,linux/arm64'
        type: string
    outputs:
      image:
        description: 'Built image reference'
        value: ${{ jobs.build.outputs.image }}
      digest:
        description: 'Image digest'
        value: ${{ jobs.build.outputs.digest }}

jobs:
  build:
    name: Build and Push
    runs-on: ubuntu-latest
    # ... resto del workflow ...
```

## Uso en el repositorio n8n:

En tu workflow principal de n8n, llamarías a estos workflows reutilizables:

```yaml
jobs:
  build:
    uses: labjp-xyz/github-workflows/.github/workflows/docker-build-push.yml@main
    with:
      image-name: n8n
      dockerfile: ./docker/images/n8n/Dockerfile
    secrets: inherit

  deploy:
    needs: build
    uses: labjp-xyz/github-workflows/.github/workflows/n8n-deploy.yml@main
    with:
      environment: production
      image-tag: ${{ needs.build.outputs.image }}
    secrets: inherit
```

## Ventajas de este enfoque:

1. **Reutilización**: Un solo lugar para mantener workflows
2. **Consistencia**: Todos los proyectos usan los mismos workflows
3. **Mantenimiento**: Actualizas en un lugar, se aplica a todos
4. **Versionado**: Puedes versionar los workflows
5. **Seguridad**: Control centralizado de permisos y secretos

## Pasos para implementar:

1. Crear repositorio `github-workflows` en tu organización
2. Agregar los workflows reutilizables
3. Actualizar el workflow de n8n para usar los reutilizables
4. Testear el flujo completo