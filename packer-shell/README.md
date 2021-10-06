## Packer img-mgr lab

For this exercise we will continue working with the img-mgr application. This time around we are going to use it to extend what we've learned with `packer` to create an immutable AMI of the application.

### Immutable servers solve the following issues taken from [here](https://aws.amazon.com/blogs/mt/create-immutable-servers-using-ec2-image-builder-aws-codepipeline/):

Here are some (fictional) examples of production incidents related to unintended differences between EC2 instances:

1.  “Four weeks ago, we inadvertently pushed a configuration file to the wrong server. It went unnoticed until yesterday, when the server was rebooted and our application did not start. It took us three hours to restore service because we initially only considered yesterday’s changes as a likely cause of the issue.”
2.  “Last week, the infrastructure team tightened network security policies. Yesterday’s sales campaign brought more traffic to the website, which meant we needed to create new EC2 instances. On startup, the instances tried to connect to an external Yum repository to install a runtime but could not reach it. The new capacity didn’t come online and the existing instances collapsed under the increased load. It took time to identify the network as the root cause. We lost hours of revenue at a crucial time for our Sales and Marketing department.”
3.  “We had a strange issue in production but were unable to reproduce it in our QA environment. For testing purposes, the QA team had recently updated the environment to run the next version of the software. Despite our best efforts, we cannot ascertain that QA is 100 percent equal to production. We hope the issue will disappear after Monday’s go-live.”

Each of these incidents is related to differences between EC2 instances. In the first example, one instance is misconfigured due to human error. In the second example, the difference is that the new instances do not have the software installed yet. External installation dependencies during system startup increase the risk of failure and slow down the startup. In the third example, there is no mechanism to reproduce an exact replica of production.

Immutable servers can help prevent these issues. When you treat instances as immutable, they will always be exact replicas of their AMI. This leads to integrity and reproducibility of the instance. When you ship fully installed AMIs, you have no more installation dependencies on startup, so there is no more risk of installations failing at the worst possible time. Shipping fully installed AMIs also reduces the time it takes to add capacity to your fleet because you don’t have to wait for the installation to finish.

It’s not a silver bullet, though. For example, the root cause of the third issue might be outside the EC2 instance. It might have originated in the data store or in an underlying service. From the example, you can’t tell with certainty. With an immutable server, though, you can at least rule out differences between EC2 instances as a suspect.

## Creating a packer AMI of our img-mgr

Provided within this repo is a `Makefile` that contains the directive to run `packer` against the provided config file `img-mgr-packer.json` within the `packer/` folder. Run this to generate an AMI within the `us-west-2` region.

## Create infra

There's a `runway/` folder within there launch the `vpc` module within there.
