---
layout: post
title: "Extending Ruby on Rails with Service Objects"
date: 2017-04-15
categories: guides
tags: ruby rails services
---

Service objects are a pattern that I believe should be part of Rails' default. This extends the basic MVC model by introducing services to implement business logic (instead of stuffing it into a model). While Rails' default assumption that each model would hold its own business logic is _sound_, it doesn't scale well when the application's size increases.

There are a lot of articles suggesting patterns on where and how to store services. My approach is mostly the same, but with a few _upgrades_. This is what an example `app/services` folder might look like:

<script src="https://gist.github.com/harigopal/c0b2ddb53f3b8e0d5875c00f33beda51.js"></script>

The main thing to note here is that there are a few _conventions_, but no strict _rules_.

## One, or few responsibilities

Naming plays a big role here - try to keep the name as specific as possible to avoid the temptation to _extend_ the responsibility of a service object. So, instead of `Users::SlackService`, it might be a better idea to call it `Users::SendSlackMessageService`.

Unlike models, with their attached database tables, it's cheap (zero cost, really) to create new services - spin new ones up whenever you encounter business logic that needs to be implemented.

## Service related to a model

<script src="https://gist.github.com/harigopal/7ebffe156a8239ccac5d7d256adefb2c.js"></script>

Services are grouped into a _pluralized-model-name_ module when the action they perform is closely related to a model. This group is for the sake of organization - nothing more, so if a service does something that's related to two models, you'll have to make a call on which module it best fits into.

## ... and when it's _not_ related to a model

<script src="https://gist.github.com/harigopal/5789ff9820bb7d86bd815654cd16c8b7.js"></script>

Frequently, business logic may not tie in directly to _any_ model. In this example, there's a third-party service that the application needs to interact with, so the module its grouped under is simply the name of the service. The `execute` method is also replaced with a `posts` method to indicate that the service returns something, instead of simply performing an action.

## Concerns to share abilities

Embrace Rails concerns when you encounter pieces of functionality that is useful in a number of situations - a common one is the ability to write to the log.

<script src="https://gist.github.com/harigopal/2d9d7ffeedbb360f70381559dbcb7766.js"></script>

Including this module into a service will allow it to easily write to the Rails log with additional information regarding the source of the message and a timestamp.

## They're easy to test

Because these are plain Ruby classes, they're generally easy to test. If you've stuck to the _Single-resposibility Principle_, the test cases should be pretty simple as well - writing a lot of small services pays off here.

## Conclusion

If you're working on a non-trivial project, services can be a massive boon. There's definitely a _back-to-the-roots_ feel to it, and that's deliberate - Ruby is an expressive, easy-to-read language, and service objects are plain Ruby classes that describe all the little pieces that form the building blocks of your application.

I've heard it said that a someone looking through your `services` folder should get a fair idea of what your application _does_, and I think that's an inevitable end-result if you write service objects properly.
