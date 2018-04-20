Requirements :
- [tfenv]( https://github.com/kamatama41/tfenv)
- [ansible 2.4.3.0](https://www.ansible.com/)
- [terraform-provider-ansible](https://github.com/nbering/terraform-provider-ansible/)([docs](https://github.com/nbering/terraform-provider-ansible/tree/v0.0.3#terraform-configuration-example)) ```[1]```
- [terraform-inventory](https://github.com/nbering/terraform-inventory/)```[1]```
- aws credentials (either using ```env vars``` or in ```~/.aws/credentials```)


# Initialize your env

run
```
tfenv install $(cat .terraform_version)

terraform init
```

# Run

```
terraform apply
```


```[1]```: [Using ansible with terraform](https://nicholasbering.ca/tools/2018/01/08/introducing-terraform-provider-ansible/)