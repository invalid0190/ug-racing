/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './App.tsx',
    './index.tsx',
    './index.html',
    './public/**/*.html',
    './dist/index.html',
    './components/**/*.{ts,tsx}',
    './hooks/**/*.{ts,tsx}'
  ],
  theme: {
    extend: {}
  },
  plugins: []
}
