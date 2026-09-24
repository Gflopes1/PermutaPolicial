// Configuração de cores por força policial
// Cores inspiradas, sem violar identidade visual oficial

export interface ForceColors {
  primary: string;
  primaryDark: string;
  primaryLight: string;
  secondary: string;
  accent: string;
  background: string;
  text: string;
  textLight: string;
}

export const forceColors: Record<string, ForceColors> = {
  pm: {
    primary: '#1a365d', // Azul escuro
    primaryDark: '#0f2027',
    primaryLight: '#2d4a6b',
    secondary: '#4a5568', // Cinza
    accent: '#2c5282',
    background: '#f7fafc',
    text: '#1a202c',
    textLight: '#718096',
  },
  bm: {
    primary: '#c53030', // Vermelho
    primaryDark: '#9b2c2c',
    primaryLight: '#e53e3e',
    secondary: '#d69e2e', // Amarelo
    accent: '#dd6b20',
    background: '#fffaf0',
    text: '#1a202c',
    textLight: '#718096',
  },
  pc: {
    primary: '#1a202c', // Preto
    primaryDark: '#0d1117',
    primaryLight: '#2d3748',
    secondary: '#d4af37', // Dourado
    accent: '#b8860b',
    background: '#fafafa',
    text: '#1a202c',
    textLight: '#4a5568',
  },
  prf: {
    primary: '#2c5282', // Azul
    primaryDark: '#1a365d',
    primaryLight: '#3182ce',
    secondary: '#d69e2e', // Amarelo
    accent: '#2b6cb0',
    background: '#ebf8ff',
    text: '#1a202c',
    textLight: '#4a5568',
  },
  pf: {
    primary: '#744210', // Marrom
    primaryDark: '#5a2d0c',
    primaryLight: '#975a16',
    secondary: '#d4af37', // Dourado
    accent: '#b7791f',
    background: '#fffaf0',
    text: '#1a202c',
    textLight: '#4a5568',
  },
  gm: {
    primary: '#1a365d', // Azul escuro
    primaryDark: '#0f2027',
    primaryLight: '#2d4a6b',
    secondary: '#a0aec0', // Prata
    accent: '#4a5568',
    background: '#f7fafc',
    text: '#1a202c',
    textLight: '#718096',
  },
};

export const getForceColors = (force: string): ForceColors => {
  return forceColors[force.toLowerCase()] || forceColors.pm;
};

