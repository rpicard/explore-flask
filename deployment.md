# Deployment

You're finally ready to show your app to the world. It's time to deploy. This process can be a pain because there are so many moving parts. There are a lot of choices to make when it comes to your production stack as well. I'm going to try and point out the important pieces and some of the options you have with each.

## The Host

You're going to need a server somewhere. There are thousands of providers out there, but these are the three that I personally recommend. I'm not going to go over the details of how to get started with them, because that's out of the scope of this book. Instead I'll talk about their benefits with regards to hosting Flask applications.

### Amazon Web Services EC2

Amazon Web Services is a collection of services provided by ... Amazon! There's a good chance that you've heard of them before as they are probably the most popular choice for new startups these days. The AWS service that we're most concerned with here is EC2, or Elastic Compute Cloud. The big selling point of EC2 is that you get virtual servers, or instances as they're called in AWS parlance, that spin up in seconds. If you need to scale your app quickly it's just a matter of spinning up a few more EC2 instances with your app running and sticking them behind a load balancer (you can even use the AWS Elastic Load Balancer).

With regards to Flask, AWS is just a regular old virtual server. You can spin it up with your favorite linux distro and install your Flask app and your server stack without much overhead. It means that you're going to need a certain amount of systems administration knowledge though.

### Heroku

Heroku is an application hosting service that is built on top of AWS services like EC2. They let you take advantage of the convenience of EC2 without the requisite systems administration experience.

With Heroku, you deploy your application with a `git push` to their server. This is really convenient when you don't want to spend you time SSHing into a server, installing and configuring software and coming up with a sane deployment procedure. This convenience comes at a price of course, though both AWS and Heroku offer a certain amount of free service.

{ SEE MORE: 

* Heroku has a tutorial on deploying Flask with their service: https://devcenter.heroku.com/articles/getting-started-with-python }


### Digital Ocean

Digital Ocean is an EC2 competitor that has recently begun to take off. Like EC2, Digital Ocean lets you spin up virtual servers, now called droplets, quickly. All droplets run on SSDs, which isn't something you get at the lower levels of EC2. The biggest selling point for me is an interface that is far simpler and easier to use than the AWS control panel. Digital Ocean is my personal preference for hosting and I recommend that you take a look at them.

The Flask deployment experience on Digital Ocean is roughly the same as on EC2. You're starting with a clean linux distribution and installing your server stack from there.

{ NOTE: Digital Ocean was nice enough to make a contribution to the Kickstarter campaign for *Explore Flask*. With that said, I promise that my recommendation comes from my own experience as a user. If I didn't like them, I wouldn't have asked them to pledge in the first place. }


## The stack

### Front server

### Application runner

### Database

## Tools and Services

### Fabric

## Summary