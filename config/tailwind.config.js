const defaultTheme = require('tailwindcss/defaultTheme')

module.exports = {
  content: [
    './public/*.html',
    './app/helpers/**/*.rb',
    './app/javascript/**/*.js',
    './app/javascript/**/*.vue',
    './app/assets/javascripts/**/*.js',
    './app/views/**/*.{erb,haml,html,slim}'
  ],
  corePlugins: {
    preflight: false
  },
  theme: {
    extend: {
      fontFamily: {
        sans: ['Inter var', ...defaultTheme.fontFamily.sans],
      },
      colors: {
        transparent: 'transparent',
        current: 'currentColor',
        'brand-warning': '#f0ad4e',
        'sn-blue': '#104DA9',
        'sn-grey': '#98a2b3',
        'sn-science-blue': '#3B99FD'
      }
    }
  },
  blocklist: [
    'collapse',
    'container'
  ],
  plugins: [
    require('@tailwindcss/aspect-ratio'),
    require('@tailwindcss/typography'),
    require('@tailwindcss/container-queries')
  ]
}
