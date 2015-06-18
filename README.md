[![Build Status](https://travis-ci.org/dalehamel/cloudshaper.svg)](https://travis-ci.org/dalehamel/cloudshaper)

# Cloudshaper

This is a tool for wrapping hashicorp's [terraform configuration](https://terraform.io/docs/configuration/index.html) with a managed workflow for:

* Sharing modules
* Instantiating many stacks
* Managing remote state
* Providing secrets securely

# Usage

To use this gem, you will need to:

* Initialize your stack
* Create a folder to contain your stack template
* Define [resources for your stack](https://terraform.io/docs/providers/index.html)
 * Preferably, use shared modules to keep things DRY
* Tune any variables for your stack resources or modules
* Configure secrets for your app (if needed)

## Configuration

### Secrets

Create a file at config/secrets.json that contains secrets needed for you providers.

Specify the secrets as a JSON hash like so:

```
{
  "aws": {
    "AWS_ACCESS_KEY_ID": "ACCESS_KEY",
    "AWS_SECRET_ACCESS_KEY": "SECRET_KEY"
  }
}
```

For other providers, see [example configs](examples/secretconfig)

**Note** do not commit plaintext secrets.json to your repository. We recommend you use [ejson](https://github.com/Shopify/ejson) to store your secrets, and [capistrano-ejson](https://github.com/Shopify/capistrano-ejson) to decrypt them in production.
**Note** Secrets are never written to module files, as a safeguared to prevent them from accidentally being committed. Instead, they are passed as environment vairables.

### YAML

After setting up your rakefile, as below, just run:

```
bundle exec rake terraform:init
```

This will set up your stacks.yml with an initial config template, which you can customize for your chosen stack module

```
common:
  remote:
    s3:
      bucket: quartermaster-terraform
      region: us-east-1
stacks:
  - name: teststack
    uuid: 8adcbfb1-fdcc-4558-8958-ea8a9e1874ea # must be unique
    description: just a test stack
    root: simpleapp
    variables:
      flavor: t1.micro
      key: SOMESSHKEY
```

You may also specify a 'common' block, that will be merged into all stacks.

Cloudshaper stacks need somewhere to store their state. By default, this will be the local filesystem.

It's highly recommended that you use a [remote backend](https://www.terraform.io/docs/commands/remote-config.html) instead, so that you can share your stacks.

### Commands

TODO

# Credits

[license](LICENSE)
