---
layout: post
title: "Shared Application State in ReasonReact"
categories: guides
tags: react reason reasonml reasonreact
---
ReasonML, if you haven't heard already, is a

`THIS GUY` wrote a superb introduction to ReasonReact, and assuming that you've gone through a bit of ReasonML's own documentation, it's an _excellent_ starting point for folks interested in building React applications with ReasonML.

The tutorial gets us building a simple Todo list app, and it uses reducers to manage application state - a feature provided out-of-the-box by ReasonReact.

```
DEMO of code in traditional callbacks-passed-as-props way.
```

Here, the shared state is managed using a reducer present in the root component, and callbacks are passed as props to child components when shared state needs to be updated.

From past experience, I find the process of passing callbacks to child components _clunky_. In larger applications, where a child component can be distant from root, adding new callbacks can deteriorate into something that looks like a relay race.

```
TodoApplication implementes editCallback()
  -> TodoList editCallback=editCallback ...
    -> TodoItem editCallback=editCallback ...
      -> TodoInlineEdit editCallback=editCallback ...
        => Use editCallback()
```

A few months ago, [Jasim](#) retweeted an article by [Blair Anderson](#) titled [_You Probably Don't Need Redux_](https://medium.com/@blairanderson/you-probably-dont-need-redux-1b404204a07f) which explains how, in a small-medium sized React application, it's often enough to pass two props - `appState` and `setAppState` to all components, allowing nested components direct access to the shared state, bypassing the need to add and _relay_ individual callbacks.

My implementation of `THIS GUY`'s tutorial mixes in this pattern, and sends two props, `appState` and `appSend`, to all components that could influence application state.

```
REPLACE WITH ACTUAL CODE.

TodoApp implements state and action types.
App uses TodoApp.state and TodoApp.action
  -> AddTodoForm appState=App.state appSend=App.send
    => props.appSend(TodoApp.AddTodo(text))
  -> TodoList appState=App.state appSend=App.send
    -> TodoItem appState=props.appState appSend=props.appSend
      => props.appSend(TodoApp.CompleteTodo(todoId))
      -> TodoInlineEdit appState=props.appState appSend=props.appSend
        => props.appSend(TodoApp.EditTodo(todoId, text))
```

`appState` as the name indicates, is the shared state, stored by the root component. `appSend` is the `send` method made available to the `render` method of the root component. We're passing that alongside `appState`, to allow all child components to trigger the root component's reducer.

Notice how, when a child component calls the prop `appSend`, it passes an action that is defined in a shared module. Since all components need access to the type definition of _state_ and all possible _actions_, they must be placed in a separate module. My first attempt at implementing this pattern kept the types _state_ and _action_ in the root component module. However, that just led to a circular dependency issue: `App -> child -> App`, blocking compilation. Extracting shared code to a different module fixed this.

Because we're using reducers, code that updates shared state is brought into the same module. Child components can now only _trigger_ changes to shared state while the nature of the state change is strictly controlled by the reducer (which should be a pure function). This makes it much easier to control and ensure correctness of shared state.

And given that we're using a language with a strong, inferred, and most importantly, _sound_ type system, we get all of its benefits as well.

I've been working on a side-project, with ES6 + React, for the past couple of months, and its increasing complexity made me search for a more _robust_ solution. I was drifting towards Typescript when [Jasim](#) and [Sherin](#) of [Protoship.io](#) suggested ReasonML as a (better) alternative.

While I'm still getting used to ReasonML and ReasonReact, my initial impressions have been generally positive. Both the language and the library are evolving rapidly at the moment. For example, while I was working through THIS GUY's tutorial and trying to adapt it to my preferences, ReasonReact updated and replaced the `self.reduce` method with the `self.send` method which is much easier to comprehend and use.

```reasonml
/* THEN: Wut? What's going on here? */
onClick={self.reduce(_event => Click)}
didMount: self => {self.reduce(() => Click, ()); NoUpdate}

/* NOW: OK... Much better. */
onClick={_event => self.send(Click)}
didMount: self => {self.send(Click); NoUpdate}
```

Over the next couple of months, I'll attempt a complete rewrite of my side-project into ReasonML. I'd been using `create-react-app`, so the presence of [reason-scripts](https://github.com/reasonml-community/reason-scripts) makes it simple... to get started. I'm sure I'll be writing more on this on a later date. :-)
