---
layout: post
title:  "Mixing React with jQuery"
date: 2016-12-22
categories: react jquery
---

For the past two weeks, I've been merrily mixing jQuery into my React components, and I have a few gotchas to share. jQuery certainly needs no introduction, but if you're new to React, check out [Facebook's _excellent_ documentation on it](https://facebook.github.io/react), and try building something with it - it's a peek into the future!

## Why even do that?

Mixing jQuery with React _felt wrong_ when I first considered it. After all, one of the prime purposes of using React is to escape from the spaghetti-code-hell that can arise when creating complex interfaces with lots of different interactions.

The thing is, however, that _that_ hell is not of jQuery's making. So the better question is _why not?_ jQuery is the default JS library available to you if you work with Rails (like I do), and it makes working with JavaScript much easier.
 
## It's all about the state.

The main issue you'll encounter if you add jQuery to a React component is unexpected interactions with React's state-based renderer. In most cases, this means issues with modifications to the DOM, made by jQuery, that React isn't aware of. Let's take the case of using your friendly neighborhood datepicker inside a component.

```jsx
class ExerciseRecord extends React.Component {
  componentDidMount() {
    $('.js-date-input').myFavDatePicker();
  }
  
  render() {
    return (
      <form onSubmit={ this.handleSubmit }>
        { this.props.exercises.map(function (exercise, index) {
          return (
            <div>
              <label>{ exercise } done on</label>
              <input className='js-date-input'
                     name={ "dates[" + exercise + "]" }/>  
            </div>
          );
        }
        <input type="submit"/>
      </form>
    );
  }
}
```

The problem above is that jQuery code doesn't account for changes made by React, which means that the datepickers are initialized only once. Any modification of `this.props.exercises` (from a parent component) that causes a re-render of this component would introduce new fields without an active datepicker.
  
The key takeaway should be that _awareness is key_ to mixing these two tools. The simplest fix for the above situation is to use `componentDidUpdate` to initialize datepickers on all updates. However repeated initializations could cause issues with the datepicker, so my preferred approach would be to extract the responsibility of maintaining the affected part into its own component:

```jsx
class DateInput extends React.component {
  onComponentDidMount() {
    $('.js-date-input-' + this.props.key).myFavDatePicker();
  }
  
  handleChange() {
    this.setState(date: $(event.target).val());
    // and maybe pass it back up the chain?
  }

  render() {
    return (
      <input className={ 'js-date-input-' + this.props.key }
             onChange={ this.handleChange }/>
    );
  }
}
```

## Server-side rendering is a no-go.

React components with jQuery inside render server-side (TODO: Confirm this)- there's no `window` for it to interact with.

## Wrap-up

Say something to end this.
