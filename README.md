# cluster_kube_azure
Deployment of a Kube Cluster on Azure

# Objectif

Ce projet GIT à pour objectif de déployer facilement un cluster Kubernetes sur Azure. Le cluster est composé d'un master et de 2 (ou plus) workers.
Il contient :
    - Un dossier Terraform, pour le déploiement des ressources nécéssaires sur Azure,
    - Un dossier Ansible, pour la configuration des composants,
    - Un dossier script, avec actuellement un seul script permettant de faire un inventaire Ansible + un fichier host en fonction des ressources déployées.

Chaque dossier est expliqué ci-dessous.


# Ressources nécéssaires au bon fonctionnement de ce projet

Le projet est créé pour fonctionner avec une Azure subscription (sub) et un Azure Resource Group (RG) dans lequel vous avez un maximum de droits. Le contexte actuel du projet est un RG mis à ma disposition par CloudGuru. L'infrastructure actuelle est assez simple, tous les prérequis sont donc remplis par le RG mis à disposition par CloudGuru.

# Variables et préparation

Pour le bon déploiement du projet, il vous faudra 5 variables primordiales, elles seront à renseigner dans le fichier "./terraform/default.tfvars" :

subscription_id                     = "<subscription_id>" # Ex "2213e8b1-dbc7-4d54-8aff-b5e315df5e5b"
rg_name                             = "<ressource_group_name>" # Ex "1-5816a712-playground-sandbox"
pub_key                             = "<pub_key_filepath>"      # Ex "~/.ssh/id_rsa_azure.pub"

address_prefix_master               = "<calico_master_pods_subnet_cidr>"  # Ex "192.168.139.192/26"
address_prefix_worker1              = "<calico_worker1_pods_subnet_cidr>" # Ex "192.168.139.192/26"
address_prefix_worker2              = "<calico_worker2_pods_subnet_cidr>" # Ex "192.168.139.192/26"


subscription_id et rg_name sont récupérables dans votre portail Azure.

pub_key est le fichier de clé publique qui sera installé sur vos VM, il est donc nécéssaire de créer une paire dont vous aurez la clé privée dans votre ordinateur.

Une fois la clé créée, créez un fichier "~/.ssh/config" avec le contenu suivant, en modifiant avec le filepath de votre clé :

```
#~/.ssh/config

Host *
    User azureadm
    IdentityFile ~/.ssh/id_rsa_azure
```
    

address_prefix_* seront récupérables une fois votre infrastructure complètement déployée. Il faudra vous connecter au master (ssh azureadm@master) et taper la commande suivante : 

```
kubectl get ipamblocks.crd.projectcalico.org \
-o jsonpath="{range .items[*]}{'podNetwork: '}{.spec.cidr}{'\t NodeIP: '}{.spec.affinity}{'\n'}"
```

# Déploiement de l'infrastructure

Une fois les 3 premières variables renseignées dans votre fichier tfvars, ouvrez un terminal dans ./terraform, puis connectez-vous à votre Azure subscription via : 

```
az login
```

Information supplémentaire : Comme les subs et les RG changent toujours, le tfstate sera corrompu à chaque renouvellement de la sandbox Azure. Il faut donc supprimer les fichiers "terraform.tfstate" et "terraform.tfstate.lock" avant de lancer un "terraform init".

Une fois la connexion effectuée, lancez l'initialisation de Terrafom :

```
terraform init
```

Enfin, vous pouvez planifier le déploiement des ressources : 

```
terrafom plan -var-file="./default.tfvars"
```

Si cela vous convient : 

```
terraform apply -var-file="./default.tfvars" --auto-approve
```

Information supplémentaire : vous pouvez agir sur toutes les variables, assurez-vous juste que vous ayez le droit de faire les modifications sur votre sub Azure.

# Récupération de l'inventaire

Une fois les ressources déployées, créez votre inventaire avec le script depuis le : 

```
sudo ../script/update_hosts_ansible.sh all <insérez_votre_resourge_group_name> # ./script/update_hosts_ansible.sh all 1-5816a712-playground-sandbox
```

Le script va récupérer l'instance "master" et les "workers" dans le ressource_group que vous aurez indiqué. Il va ensuite mettre à jour /etc/hosts ainsi que le fichier ./ansible/inventory.yaml.

# Déploiement de la configuration via Ansible

Une fois l'inventaire mis à jour, lancez le playbook via la commande : 

```
cd ../ansible
```
``` 
ansible-playbook main.yml -i inventory.yml
```

Le playbook se lance, il faut attendre +- 10min pour configurer le cluster au complet.

# Configuration des route tables pour la discussion inter-nodes

Sur Azure, il est impossible que les nodes (VM séparées) discutent entre eux si vous ne leur indiquez pas le chemin réseau à suivre. Pour cela, il convient de créer une route table qui sera assignée à votre subnet, et d'y indiquer les tables correspondant à vos subnets.

Connectez-vous donc sur le master (ssh azureadm@master) puis lancez la commande indiquée ci-dessus :

```
kubectl get ipamblocks.crd.projectcalico.org \
-o jsonpath="{range .items[*]}{'podNetwork: '}{.spec.cidr}{'\t NodeIP: '}{.spec.affinity}{'\n'}"
```

Vous aurez un output du type :

```
podNetwork: 192.168.108.128/26   NodeIP: host:dev-p00001a00001-0
podNetwork: 192.168.139.192/26   NodeIP: host:dev-p00001a00001-1
podNetwork: 192.168.70.64/26     NodeIP: host:dev-p00001a00001-2
podNetwork:      NodeIP:
```

Indiquez alors dans le fichier "default.tfvars" les subnets associés à votre nodes. A savoir que le node 0 correspond toujours au master, les workers suivent dans l'ordre.

Une fois les variables mises à jours, vous pouvez relancer le terraform. 

Depuis le dossier terraform : 

```
terraform apply -var-file="./default.tfvars" --auto-approve
```

La route table sera alors correctement configurée, vous devriez alors pouvoir faire discuter vos Pods entre eux et ce, même si ils sont sur des nodes différents. Attention à ne pas oublier d'appliquer une network_policy (Calico) donnant accès aux pods.
