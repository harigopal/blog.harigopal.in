module.exports = {
  purge: [
    './_includes/*.html',
    './_layouts/*.html',
  ],
  darkMode: false, // or 'media' or 'class'
  theme: {
    extend: {},
    fontFamily: {
      'sans': ['Nunito\\ Sans', 'sans-serif'],
      'serif': ['Lora', 'serif']
    }
  },
  variants: {
    borderWidth: ['responsive', 'hover'],
  },
  plugins: [],
}
