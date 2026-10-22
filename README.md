# Mini Proyecto Terraform — Nivel 1 (Base AWS)

Proyecto de práctica de Terraform / IaC sobre AWS: una VPC con subnet pública y
subnet privada, Internet Gateway, Security Group restringido por IP, y una
instancia EC2 accesible por SSH.

Hecho como ejercicio de aprendizaje (Nivel 1 de un plan de estudio hacia roles
DevOps/Cloud Architect junior), no pensado para producción.

## Qué crea

- **VPC** (`10.0.0.0/16`) con DNS support/hostnames habilitado.
- **Subnet pública** (`10.0.1.0/24`) con ruta a internet vía Internet Gateway.
- **Subnet privada** (`10.0.2.0/24`) sin ruta de salida a internet (sin NAT Gateway).
- **Internet Gateway** + route table pública asociada a la subnet pública.
- **Route table privada** sin rutas adicionales (solo la ruta local que añade AWS).
- **Security Group** que permite SSH (22) únicamente desde tu IP (`/32`); egress abierto a todo.
- **Key pair** gestionado por Terraform a partir de una clave pública local.
- **Instancia EC2** (Ubuntu 22.04, resuelto vía `data "aws_ami"`, siempre la AMI más reciente) en la subnet pública.

## Estructura

```
main.tf             # provider + todos los resources/data sources
variables.tf         # declaración de variables
outputs.tf           # ip pública, id de instancia, id de VPC
terraform.tfvars      # valores locales (NO se sube a git)
```

## Requisitos previos

- [Terraform](https://developer.hashicorp.com/terraform/install) instalado.
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) instalado y configurado (`aws configure`) con un **usuario IAM** (nunca con las claves del usuario root).
- Un par de claves SSH generado localmente, fuera de este repo:
  ```powershell
  ssh-keygen -t ed25519 -f "C:\ruta\que\quieras\mini-terraform-key" -C "mini-proyecto-terraform"
  ```

## Variables a definir

Declaradas en `variables.tf`. Las que no tienen `default` hay que ponerlas en `terraform.tfvars`:

| Variable | Default | Descripción |
|---|---|---|
| `region` | `eu-west-1` | Región de AWS |
| `vpc_cidr` | `10.0.0.0/16` | CIDR de la VPC |
| `subnet_cidr` | `10.0.1.0/24` | CIDR de la subnet pública |
| `private_subnet_cidr` | `10.0.2.0/24` | CIDR de la subnet privada |
| `instance_type` | `t2.micro` | Tipo de instancia EC2 |
| `my_ip` | *(sin default, obligatoria)* | Tu IP pública en formato `x.x.x.x/32`, para el Security Group |

Ejemplo de `terraform.tfvars` (fichero local, no versionado):

```hcl
my_ip = "88.21.75.154/32"
```

Tu IP pública se puede consultar con:
```powershell
(Invoke-RestMethod ifconfig.me)
```

> La ruta a la clave pública (`public_key = file(...)`) en el `aws_key_pair` del
> `main.tf` está hardcodeada a una ruta local absoluta — pendiente de
> parametrizar como variable para que el proyecto sea portable entre máquinas.

## Uso

```powershell
terraform init       # descarga el provider de AWS
terraform validate   # comprueba sintaxis y referencias, sin llamar a AWS
terraform plan        # muestra qué se va a crear/cambiar, sin aplicar nada
terraform apply       # crea los recursos (pide confirmación con "yes")
```

Tras el `apply`, los outputs muestran la IP pública y el id de la instancia:

```powershell
terraform output
```

Conectar por SSH:
```powershell
ssh -i "C:\ruta\a\mini-terraform-key" ubuntu@<mini_server_public_ip>
```

## Limpieza

Este proyecto crea recursos reales en AWS (dentro del free tier si la cuenta
es nueva — ninguno de los recursos aquí, al no haber NAT Gateway, tiene coste
fuera de la instancia EC2). Para no dejar nada corriendo:

```powershell
terraform destroy
```

## Pendiente / mejoras futuras

- [ ] Restringir el `egress` del Security Group (ahora mismo permite todo el tráfico saliente) a los puertos mínimos necesarios (DNS 53, HTTP 80, HTTPS 443, NTP 123).
- [ ] Parametrizar la ruta de la clave pública del `aws_key_pair` como variable.
- [ ] Separar `region` sin `default` para forzar su elección explícita.
- [ ] Nivel 2: NAT Gateway para la subnet privada, módulos, remote state.

## Seguridad / notas de diseño

- `terraform.tfstate`, `*.tfvars` y `.terraform/` están en `.gitignore` — nunca se suben a git porque pueden contener IPs, IDs de cuenta o valores de variables sensibles.
- El acceso SSH está limitado a una única IP `/32`, no abierto a `0.0.0.0/0`.
- Las credenciales de AWS usadas son de un usuario IAM dedicado (`terraform-cli`), no del usuario root de la cuenta.
