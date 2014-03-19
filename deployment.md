# Deployment

You're finally ready to show your app to the world. It's time to deploy. This process can be a pain because there are so many moving parts. There are a lot of choices to make when it comes to your production stack as well. I'm going to try and point out the important pieces and some of the options you have with each.

## The Host

You're going to need a server somewhere. There are thousands of providers out there, but these are the three that I personally recommend. I'm not going to go over the details of how to get started with them, because that's out of the scope of this book. Instead I'll talk about their benefits with regards to hosting Flask applications.

### Amazon Web Services EC2

Amazon Web Services is a collection of services provided by ... Amazon! There's a good chance that you've heard of them before as they are probably the most popular choice for new startups these days. The AWS service that we're most concerned with here is EC2, or Elastic Compute Cloud. The big selling point of EC2 is that you get virtual servers, or instances as they're called in AWS parlance, that spin up in seconds. If you need to scale your app quickly it's just a matter of spinning up a few more EC2 instances with your app running and sticking them behind a load balancer (you can even use the AWS Elastic Load Balancer).

With regards to Flask, AWS is nice because it's just a regular old virtual server. You can spin it up with your favorite linux distro and install your app and your server stack without much overhead. It also means that you're going to need a certain amount of systems administration knowledge though.

### Heroku

Heroku is a really 

### Digital Ocean


## The stack

### Front server

### Application runner

### Database

## Tools and Services

### Fabric

## Summary