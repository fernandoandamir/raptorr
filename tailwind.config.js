/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,jsx}'],
  theme: {
    extend: {
      fontFamily: {
        display: ['"Bebas Neue"', 'sans-serif'],
        body: ['"DM Sans"', 'sans-serif'],
        mono: ['"JetBrains Mono"', 'monospace'],
      },
      colors: {
        raptor: {
          // Core dark palette
          void:    '#080A0C',
          abyss:   '#0D1117',
          pit:     '#111820',
          dark:    '#161E28',
          mid:     '#1C2733',
          surface: '#212D3A',
          raised:  '#273545',
          border:  '#2E3D50',
          muted:   '#3D5068',
          // Amber accent
          amber:   '#F59E0B',
          gold:    '#FBBF24',
          ember:   '#D97706',
          // Status
          online:  '#22C55E',
          idle:    '#F59E0B',
          dnd:     '#EF4444',
          ghost:   '#6B7280',
          // Text
          text:    '#E2EAF3',
          sub:     '#8FA8C0',
          faint:   '#4D6278',
        },
      },
      animation: {
        'fade-in':    'fadeIn 0.2s ease-out',
        'slide-up':   'slideUp 0.25s ease-out',
        'slide-in':   'slideIn 0.2s ease-out',
        'ping-slow':  'ping 2s cubic-bezier(0,0,0.2,1) infinite',
        'glow-pulse': 'glowPulse 2s ease-in-out infinite',
      },
      keyframes: {
        fadeIn:    { from: { opacity: 0 },                     to: { opacity: 1 } },
        slideUp:   { from: { opacity: 0, transform: 'translateY(8px)' }, to: { opacity: 1, transform: 'translateY(0)' } },
        slideIn:   { from: { opacity: 0, transform: 'translateX(-8px)' }, to: { opacity: 1, transform: 'translateX(0)' } },
        glowPulse: { '0%,100%': { opacity: 0.6 }, '50%': { opacity: 1 } },
      },
    },
  },
  plugins: [],
}
