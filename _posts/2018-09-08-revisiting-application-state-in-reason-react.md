---
layout: post
title: "Revisiting Application State in ReasonReact"
date: 2018-09-08 15:30:00 +0530
categories: guides
tags: react reason reasonml reasonreact
---

{{ '201809/frame_1_oops.png' | image_from_cdn:'Oops' }}

## TL;DR (aka, just tell me what you were wrong about)

1.  Passing `appState` to all components is not a good idea. `appState` contains _unresolved possible states_ that individual components usually don't care about, but, which you'll still be forced to handle since ReasonML is a strongly typed language.
2.  Instead of passing state, pass `ctx` (context). My current approach is to pass a `ctx` record to each component that contains the _resolved_ information _derived_ from state, that the particular component _needs_. This allows the component to function with _certain knowledge_ about the context in which it will render.
3.  Passing `appSend` to all components (like before) is fine — it's just a function with which we _affect_ application state.

## And in much more detail…

I'd written about a method to maintain [Application State in ReasonReact](https://medium.com/@elvesbane/application-state-in-reasonreact-1626859366a8) back in April, and I've worked with ReasonML a lot more since then, completing the conversion of [Turaku's codebase](https://github.com/turakuapp/turaku-client/) from ES6 to Reason, and it turns out that my approach in the previous article didn't _work_ as well as I expected it to.

Passing around application state as `appState` is a bad idea with ReasonML. Passing around `appSend` appears to be fine.

{{ '201809/frame_2_return.png' | image_from_cdn:'Do not pass appState' }}

Why? Well, one of the basic tenants of functional programming is to _make illegal states unrepresentable_. Put simply, it means that the structures that define and hold our data should not allow the possibility of incorrect state. This is nearly impossible to achieve with dynamically typed languages, and unless this is a principle you've already grokked, do yourself a favour and watch Richard Feldman's awesome talk titled "[Making Impossible States Impossible](https://www.youtube.com/watch?v=IcgmSRJHu_8)".

I'm gonna continue assuming that you've watched the video.

One of the tools that ReasonML gives us to describe a _thing_ that could be _one of a set of things_ is something called _Variant_ (union type). In Turaku's application state definition, there are types that looks a bit like this (simplified):

<script src="https://gist.github.com/harigopal/15dc0ae18cbfe96852755a9c3b505a59.js"></script>

Looking at the basic type `state`, it's pretty easy to tell that we've described our user's state in the application as _always_ being one of two — either the user is signed out (and on a public page), or the user is signed in (and has some corresponding user data).

_Variants_ allow ReasonML's compiler to ensure that whenever we handle a value of a _variant_ type, all of its possibilities are considered. For example, in the root component, when trying to determine which view to render, we could use `switch`, like so:

<script src="https://gist.github.com/harigopal/d902f64731da6718127a022dced3a0c1.js"></script>

The compiler can be configured to either issue warnings or raise errors if we've forgotten to deal with all the defined _variants_ that a type can _be_. You'll notice that I'm not passing `appState` to any of these components, yet. So let's try that with the `Dashboard` component.

The `Dashboard` contains the main user interface that a signed in user is expected to interact with. Let's send it `appState` and `appSend` …

<script src="https://gist.github.com/harigopal/e1b76503351eb7510389ac5c7dd56c66.js"></script>

… and then take a peek inside `Dashboard` to see how we could render a list of available teams:

<script src="https://gist.github.com/harigopal/9c687bd91dce3b2b6ebed0447a3f946d.js"></script>

The problem should be obvious now. `appState` is a _variant_ (or can contain nested variants), and its contents can only be accessed through pattern-matching. Because of this, the component is being forced to handle all possible cases even though we know that the dashboard will never be rendered without a user being signed in.

Thankfully, the fix is simple. It is to **not** pass application state around.

Application state is a structure that represents all possible states that the application could be in. However, the process of rendering an _inner_ component involves the _condensing_ of those possibilities. What we _should_ do, is to define the _context_ in which the component is expected to render.

In the above example, it is meaningless for the `Dashboard` component to render for a signed out user, so the fix is to ensure that the component's expected context includes the information that is available with a signed in user...

<script src="https://gist.github.com/harigopal/73081eca3487b7a8a4c4055c3e1f27ea.js"></script>

Now, the compiler will make sure that the component is invoked with a valid context.

<script src="https://gist.github.com/harigopal/b539377f36f449a237e954116a85b1dd.js"></script>

{{ '201809/frame_3_ctx.png' | image_from_cdn:'A bag called context' }}

That's it... except... it looks like we're back to the days of _prop drilling_ - which I'd advocated against in my last article.

We are, but only partially. Note that we're still passing `appSend` around, allowing us to eliminate callback functions. `appSend` gives components access to _all_ of the application state reducer's _actions_.

This is also where the `ctx` record comes in. I've found it really convenient to wrap everything in a single record so that I can pass it around functions - this also helps avoid the worst effects of prop drilling - where you'd have to thread new props around functions within components to get them where they need to be. By wrapping the props into `ctx`, and treating it as a bag of values to be accessed wherever needed, we're restricting the _threading / drilling_ to the entry and exit points of components.

It also makes sense for the `ctx` record to grow, as it's passed into deeper components, with parent components _resolving_ more of the possibilities of application state, and passing a more _definite_ context to their children.

Obviously, using `ctx` record is optional. Passing individual props also works, and deciding between wrapping props or leaving them unwrapped seems to be a decision between reducing the overhead of prop-drilling, or improving the cleanliness of the component call-site.

{{ '201809/frame_4_jetpack.png' | image_from_cdn:'A jetpack, not a backpack' }}

## So what's the takeaway?

Passing `appState` was a _pattern_ that worked well with dynamic languages. In fact, if we structure the state similar to how we'd write it in a dynamic language - without using the features that strong typing gives us (such as variants), then it's possible to continue to use `appState`.

_But_, if we use ReasonML _correctly_, with the intention of _making illegal states unrepresentable_, then old patterns prove insufficient. This partial retraction of mine grew out of a better understanding of how to write to functional code.

{{ '201809/frame_5_fly.png' | image_from_cdn:'Bye bye' }}
