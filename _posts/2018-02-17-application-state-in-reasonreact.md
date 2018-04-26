---
layout: post
title: "Application State in ReasonReact"
date: 2018-02-17 02:45:00 +0530
categories: guides
tags: react reason reasonml reasonreact
canonical_url: 'https://turaku.com/blog/2018/02/application-state-in-reasonreact.html'
---

{{ '201802/callback_1.png' | image_from_cdn:'The Callback Relay Race - Page 1' }}

_This post was originally published on [Turaku's blog](https://turaku.com/blog)._

## TL;DR?

I've modified Jared Forsyth's tutorial on ReasonReact, improving application state management. By sending two props, `appState` and `appSend` to all child components, we allow them influence shared state directly, instead of relying on a complex web of callbacks. Sound interesting?

## Go on...

Want to implement shared state in _ReasonReact_ applications..?

Probably not, if I'm being practical. The likelyhood of you, the reader, having even heard about _ReasonML_, let alone _ReasonReact_, is small. While _Reason_ was featured in [_theStateOfJs 2017_](https://stateofjs.com/2017/flavors/results/), ~80% of survey respondents said that they'd never heard of it. So if you haven't, that's totally OK. Head over to [ReasonML's homepage](https://reasonml.github.io/) right now, and give this new (sort of?) language a spin. It's **cool**, it's built by the folks behind React, and is backed by the might of OCaml.

However, if you're among the ~19.2% who've heard about [ReasonML](https://reasonml.github.io/reason-react), or the ~0.8% who've actually tried it **and** wondered about how shared / global state can work, this tutorial is for **you**! All of the code I'll refer to in this article is available [on this repo](http://github.com/harigopal/react-re-exp).

## But first, some background

Last year, [Jared Forsyth](https://jaredforsyth.com) published [_A ReasonReact Tutorial_](https://jaredforsyth.com/2017/07/05/a-reason-react-tutorial/), an excellent starting point for folks interested in building React applications with ReasonML. The tutorial involves building a simple Todo list app, using reducers to manage application state &mdash; a feature provided out-of-the-box by ReasonReact. The application structure looks _something_ like this:

```
App implements reducer(action)
  -> TodoItem onToggle=send(Toggle)
  -> TodoInput onSubmit=send(AddItem(text))
```

Here the application state is managed in the root component through a reducer, but child components can update application state only through callbacks that are passed down as props from _root_.

This process of passing callbacks to child components is clunky. In larger applications, where a child component can be distant from root, adding new callbacks can deteriorate into something that looks like a relay race. Here's an example:

```
App implementes editCallback(), deleteCallback(), ...
  -> TodoItem editCallback=editCallback deleteCallback=deleteCallback...
    -> TodoInlineEditor editCallback=editCallback deleteCallback=deleteCallback...
      => Use editCallback()
      -> TodoDeleteButton deleteCallback=deleteCallback
        => Use deleteCallback()
```

{{ '201802/callback_2.png' | image_from_cdn:'The Callback Relay Race - Page 2' }}

[Blair Anderson](#) wrote an excellent article titled [&ldquo;You Probably Don&rsquo;t Need Redux&rdquo;](https://medium.com/@blairanderson/you-probably-dont-need-redux-1b404204a07f) which explains how, in small-to-medium sized React applications, it's often enough to pass two props &mdash; `appState` and `setAppState` to all components, allowing nested components direct access to the shared state, bypassing the need to add and _relay_ individual callbacks.

My implementation of Jared's tutorial mixes this idea in, and sends two props, `appState` and `appSend`, to all components that could influence shared state. For the sake of clarity, I'm only going to point out parts of the code that diverge from Jared's tutorial.

## A reasonable alternative

<script src="https://gist.github.com/harigopal/974109e09597ac17ca71d09eb4000770.js"></script>

`appState` as the name indicates, is the shared state, stored by the root component. `appSend` is the `send` method made available to the `render` method of the root component. We're passing that alongside `appState`, to allow child components to trigger the root component's reducer. The `TodoForm` component doesn't need the `appState` prop because it never reads shared state.

<script src="https://gist.github.com/harigopal/978e4e5b08431bb420fdb7a9896ada12.js"></script>

When the `TodoItem` component uses the prop `appSend`, it passes an action `TodoApp.ToggleItem`. To correctly resolve the it as `type action`, we need to explicity mention the namespace &mdash; the shared module `TodoApp`. Since all components need access to the type definition of _state_ and all possible _actions_, they [must be placed in this separate shared module](https://github.com/harigopal/react-re-exp/blob/master/src/TodoApp.re).

My first attempt at implementing this pattern kept the types _state_ and _action_ in the root component module. However, that just led to a circular dependency issue: `App -> child -> App`, blocking compilation. Extracting shared code to a different module fixed this.

That's pretty much it. Notice how there are no callback functions anywhere?

{{ '201802/callback_3.png' | image_from_cdn:'The Callback Relay Race - Page 3' }}

## Advantages, and a few caveats

With ReasonReact, we're using reducers by default, so code that updates shared state is brought into the same module. Child components can now only _trigger_ changes to shared state while the nature of the state change is strictly controlled by the reducer (which should be a pure function). This makes it much easier to control and ensure correctness of shared state.

And given that we're using a language with a strong, inferred, and most importantly, _sound_ type system, we get all of its benefits as well.

One thing that I'm not _totally_ happy with is that I was forced to `open TodoApp` (first line in `App.re` gist above) within the `App` module. TodoApp defines the `state` and `action` types that the `App` component relies on, and I kept running into syntax errors when I tried to annotate types. All the other modules have manual type annotation when they first refer to either the shared `state` or an `action`. _Opening_ TodoApp in the `App` module isn't a big issue though, since it's the root component.

Re-visiting the earlier contrived example with our new pattern, we end up with:

```
TodoApp implements state and action types, and the reducer.

App uses TodoApp.state, TodoApp.action and TodoApp.reducer
  -> TodoItem appState=App.state appSend=App.send
    -> TodoInlineEditor appState=App.state appSend=App.send
      => props.appSend(TodoApp.Edit(todoId, text))
      -> TodoDeleteButton appSend=App.send
        => props.appSend(TodoApp.Delete(todoId))
```

I think this is a clearer, and more consise approach than callback-passing. There's no need to add more _batons_ to the relay race either, when new actions need to be handled.

## Conclusion

I've been working on a personal project, [Turaku](https://www.turaku.com) - a password manager for teams, with ES6 + React, for the past couple of months, and its increasing complexity meant that the pain of refactoring and adding new features was slowly increasing from _mere annoyance_ to _stinging_. In my search for a more _robust_ environment, I was drifting towards Typescript when [Jasim](#) and [Sherin](#) of [Protoship.io](#) suggested ReasonML as a (better) alternative.

While I'm still getting used to ReasonML and ReasonReact, my initial impressions have been generally positive. Both the language and the library are evolving rapidly at the moment. For example, while I was working through Jared's tutorial and trying to adapt it to my preferences, ReasonReact updated and replaced the `self.reduce` method with the `self.send` method which is much easier to comprehend and use.

<script src="https://gist.github.com/harigopal/89cddfb3ce8f0b74cfc484e2529070c0.js"></script>

The ReasonML compiler error messages can be pretty confusing at times though. And all too often, it just barks that there's _something_ wrong with my syntax on a line, informs me that it crashed because of this, and asks me to file a bug on Reason's repository. `¯\_(ツ)_/¯` Growing pains, I guess.

Over the next couple of months, I'll attempt a complete re-write of Turaku's code into ReasonML. I'd been using `create-react-app`, so the presence of [reason-scripts](https://github.com/reasonml-community/reason-scripts) makes it simple to get started. I'm sure I'll be writing more related to this on a later date. :-)

### Credits

Art by Rekha Soman: <a href="http://www.rekhasoman.com" target="_blank">www.rekhasoman.com</a>