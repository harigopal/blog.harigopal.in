---
layout: post
title:  "Validating Rails API requests with Reform"
date: 2017-09-13
categories: guides
tags: ruby rails services
---

I've written about the creation of custom exception classes to organize code in Rails web applications and APIs. However, while going through my previous article, I realized that my final example glossed over how request parameter validation failures would be detected by the API in the first place.

Today I want to discuss a pattern that I haven't seen in the wild - one which uses *Reform* - form objects, decoupled from models (their description) - and exception classes to *beautifully* manage API parameter validation.

## An intro to form objects, for those unfamiliar with it.

If you haven't used form objects before, know that they allow you to decouple validation of input from the user (via forms), and the validation of data managed by a `Model`. My primary reason for favoring this separation is that it allows the model validations to be less constrained than form validation.

Validations failures from a model should be **unexpected**, whereas form validations are always **expected** (users make mistakes) and thus should be handled as a natural part of your application. Decoupling in this manner also makes it easy to manage multiple forms that interact with one or more models, with different validation requirements. Google `form validation vs model validation` to learn more.

## But API-s don't *have* forms. Right?

No, they don't. What they do have are end-points where you _POST_ data, and expect something about your application's database to change. Such data needs to be validated. This article is going to focus on how to use *Reform* - a library meant for validating data submitted by _users_ into _forms_, to validate data submitted by _clients_ to _API endpoints_. *Clients* instead of *users*, and _API endpoints_ instead of _forms_. Let's begin.

## POST /api/users/invite

Let's assume that we need to implement a simple _invite_ route for our API - to invite other users to join our platform. It accepts just two parameters:

1. `name`
2. `email`

...and responds with a `200 OK` if the invitation can be processed.

However, as with all such requests, there are conditions which must be fulfilled before the request can be executed. Let's list down three simple requirements:

1. `email` is required.
2. `email` must look like an email address.
3. `name` is optional, but if present, it must be longer than 3 characters.

The last one is a bit contrived, but this is just a demonstration. ¯\_(ツ)_/¯

## Create a Reform Form.

Let's get the basics out of the way. Setting up _Reform_ should be pretty simple. Add `gem 'reform-rails', '~> 0.1.7'` to your `Gemfile`, and run `bundle install`. That should be it. Now, let's build our form object.

<script src="https://gist.github.com/harigopal/1de28e963edeed26e9580fb00749e2a3.js"></script>

`reform-rails` allows you to write validations in much the same way that you'd write validations for regular Rails models. Granted that this is a very simple form, but even complex Reform forms are readable, and its API is rich and flexible.

If you're confused by `email: true`, I'm assuming the presence of a custom Rails validator. For an example, check out [Rails' documentation on adding custom validators](http://guides.rubyonrails.org/active_record_validations.html#custom-validators).

Note that I'm overriding the default `save` method, since I don't want Reform touching the model. I advise keeping code handling the _actual_ invitation out of the form. Our form is responsible for data validation, not operations. [Leave business logic to services.](/guides/extending-ruby-on-rails-with-service-objects)

##  Set up the endpoint.

<script src="https://gist.github.com/harigopal/ec811f2bc3cf7e9f18006a3a3349c4dd.js"></script>

_Reform_ requires explicit validation which, I think, reads better than the _Rails way_. Unlike Rails' `if @user.save`, _Reform_ asks the form object to validate the form with the supplied params, _and then_ do something if the validation passes (or something else when it fails).

In this case, a failure to validate lets us raise `ValidationException`, passing it the form object. This is a custom exception which [I'd elaborated on in a previous article](/guides/exceptions-as-first-class-citizens-on-rails). Let's take another look.

## ValidationFailureException

I'm going to extend an `ApplicationException` class that I went into detail in my article on exception classes:

<script src="https://gist.github.com/harigopal/ab851d1f2a0a8bb8a4a70409ad03c2b2.js"></script>

Coupled with application level exception handling, as described in my previous post, if you _POST_ to the API with invalid data, it responds with a lot of detail.

<script src="https://gist.github.com/harigopal/1152bb382b07e8087ffea534e602f8e8.js"></script>

Isn't that beautiful?

Those validation errors can now be used by the client to display the failure to the user. Obviously, this needs to be set up only once. As long as you validate params with Reform, and pass the form with the errors to `ValidationFailureException` when raising it, responses in a standard format are taken care of.

## Conclusion

Form objects are a great abstraction that allow us to deal with of the process of validating user input in one place. If you're building an API for other developers or the public, good documentation is an absolute necessity. And while invalid form submissions showing users what's wrong is commonplace, APIs doing something similar for their clients is _rare_.

Using Reform, it's possible to give consumers of your API insights into what went wrong the same way a user entering incorrect information into a form is treated. Sure, once set up, an API client won't make (the same) mistake again. But when integrating with a new API, a little help can go a long way.
