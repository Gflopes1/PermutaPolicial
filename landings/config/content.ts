// Conteúdo base e personalizado por força

export interface ForceContent {
  id: string;
  name: string;
  headline: string;
  subheadline: string;
  description: string;
  benefits: string[];
  whyBenefit: string;
  categories: {
    title: string;
    description: string;
  }[];
}

export const forceContent: Record<string, ForceContent> = {
  pm: {
    id: 'pm',
    name: 'Polícia Militar',
    headline: 'Para quem vive a rotina do patrulhamento e precisa de equipamentos confiáveis.',
    subheadline: 'A maior comunidade de compra e venda entre profissionais da segurança pública',
    description: 'Equipamentos, acessórios, viaturas, artigos operacionais e muito mais — publicados e negociados por quem realmente vive a rotina de rua.',
    benefits: [
      'Compra e venda direta entre operadores',
      'Perfis verificados',
      'Crescimento orgânico da comunidade (média 4% ao dia — 2 a 8 novos cadastros/dia)',
      'Mais de 140 usuários ativos e crescendo',
      'Produtos e conteúdos específicos para PM',
    ],
    whyBenefit: 'A Polícia Militar precisa de equipamentos que resistam ao dia a dia do patrulhamento. Nossa plataforma conecta profissionais que entendem essas necessidades, oferecendo produtos testados em campo por quem realmente usa.',
    categories: [
      {
        title: 'Acessórios operacionais',
        description: 'Equipamentos essenciais para o patrulhamento diário',
      },
      {
        title: 'Viaturas e veículos',
        description: 'Veículos adaptados para operações policiais',
      },
      {
        title: 'Produtos táticos',
        description: 'Equipamentos táticos de alta qualidade',
      },
      {
        title: 'Equipamentos de serviço',
        description: 'Ferramentas e equipamentos para o trabalho diário',
      },
      {
        title: 'Itens de coleção',
        description: 'Itens especiais e colecionáveis',
      },
    ],
  },
  bm: {
    id: 'bm',
    name: 'Bombeiros Militares',
    headline: 'Para quem atua no fogo, resgate e salvamento.',
    subheadline: 'A maior comunidade de compra e venda entre profissionais da segurança pública',
    description: 'Equipamentos, acessórios, viaturas, artigos operacionais e muito mais — publicados e negociados por quem realmente vive a rotina de rua.',
    benefits: [
      'Compra e venda direta entre operadores',
      'Perfis verificados',
      'Crescimento orgânico da comunidade (média 4% ao dia — 2 a 8 novos cadastros/dia)',
      'Mais de 140 usuários ativos e crescendo',
      'Produtos e conteúdos específicos para BM',
    ],
    whyBenefit: 'Bombeiros Militares precisam de equipamentos que garantam segurança e eficiência em situações de emergência. Nossa plataforma reúne profissionais que compartilham conhecimento sobre os melhores equipamentos para combate a incêndio, resgate e salvamento.',
    categories: [
      {
        title: 'Acessórios operacionais',
        description: 'Equipamentos essenciais para operações de bombeiro',
      },
      {
        title: 'Viaturas e veículos',
        description: 'Veículos adaptados para operações de resgate',
      },
      {
        title: 'Produtos táticos',
        description: 'Equipamentos táticos para bombeiros',
      },
      {
        title: 'Equipamentos de serviço',
        description: 'Ferramentas e equipamentos para salvamento',
      },
      {
        title: 'Itens de coleção',
        description: 'Itens especiais e colecionáveis',
      },
    ],
  },
  pc: {
    id: 'pc',
    name: 'Polícia Civil',
    headline: 'Para quem investiga, apura e precisa de ferramentas eficientes.',
    subheadline: 'A maior comunidade de compra e venda entre profissionais da segurança pública',
    description: 'Equipamentos, acessórios, viaturas, artigos operacionais e muito mais — publicados e negociados por quem realmente vive a rotina de rua.',
    benefits: [
      'Compra e venda direta entre operadores',
      'Perfis verificados',
      'Crescimento orgânico da comunidade (média 4% ao dia — 2 a 8 novos cadastros/dia)',
      'Mais de 140 usuários ativos e crescendo',
      'Produtos e conteúdos específicos para PC',
    ],
    whyBenefit: 'A Polícia Civil precisa de ferramentas precisas e confiáveis para investigações e apurações. Nossa plataforma conecta investigadores que compartilham conhecimento sobre equipamentos essenciais para o trabalho investigativo.',
    categories: [
      {
        title: 'Acessórios operacionais',
        description: 'Equipamentos essenciais para investigações',
      },
      {
        title: 'Viaturas e veículos',
        description: 'Veículos adaptados para operações investigativas',
      },
      {
        title: 'Produtos táticos',
        description: 'Equipamentos táticos para operações especiais',
      },
      {
        title: 'Equipamentos de serviço',
        description: 'Ferramentas e equipamentos para investigação',
      },
      {
        title: 'Itens de coleção',
        description: 'Itens especiais e colecionáveis',
      },
    ],
  },
  prf: {
    id: 'prf',
    name: 'Polícia Rodoviária Federal',
    headline: 'Para quem vive a estrada e precisa de equipamentos de alta confiabilidade.',
    subheadline: 'A maior comunidade de compra e venda entre profissionais da segurança pública',
    description: 'Equipamentos, acessórios, viaturas, artigos operacionais e muito mais — publicados e negociados por quem realmente vive a rotina de rua.',
    benefits: [
      'Compra e venda direta entre operadores',
      'Perfis verificados',
      'Crescimento orgânico da comunidade (média 4% ao dia — 2 a 8 novos cadastros/dia)',
      'Mais de 140 usuários ativos e crescendo',
      'Produtos e conteúdos específicos para PRF',
    ],
    whyBenefit: 'A Polícia Rodoviária Federal opera em condições extremas nas estradas brasileiras. Nossa plataforma reúne profissionais que conhecem os equipamentos mais adequados para operações rodoviárias, garantindo segurança e eficiência.',
    categories: [
      {
        title: 'Acessórios operacionais',
        description: 'Equipamentos essenciais para operações rodoviárias',
      },
      {
        title: 'Viaturas e veículos',
        description: 'Veículos adaptados para patrulhamento rodoviário',
      },
      {
        title: 'Produtos táticos',
        description: 'Equipamentos táticos para operações em estradas',
      },
      {
        title: 'Equipamentos de serviço',
        description: 'Ferramentas e equipamentos para o trabalho rodoviário',
      },
      {
        title: 'Itens de coleção',
        description: 'Itens especiais e colecionáveis',
      },
    ],
  },
  pf: {
    id: 'pf',
    name: 'Polícia Federal',
    headline: 'Para quem atua na proteção federal e busca desempenho e segurança.',
    subheadline: 'A maior comunidade de compra e venda entre profissionais da segurança pública',
    description: 'Equipamentos, acessórios, viaturas, artigos operacionais e muito mais — publicados e negociados por quem realmente vive a rotina de rua.',
    benefits: [
      'Compra e venda direta entre operadores',
      'Perfis verificados',
      'Crescimento orgânico da comunidade (média 4% ao dia — 2 a 8 novos cadastros/dia)',
      'Mais de 140 usuários ativos e crescendo',
      'Produtos e conteúdos específicos para PF',
    ],
    whyBenefit: 'A Polícia Federal atua em operações de alta complexidade que exigem equipamentos de última geração. Nossa plataforma conecta profissionais federais que compartilham conhecimento sobre os melhores equipamentos para operações especiais.',
    categories: [
      {
        title: 'Acessórios operacionais',
        description: 'Equipamentos essenciais para operações federais',
      },
      {
        title: 'Viaturas e veículos',
        description: 'Veículos adaptados para operações especiais',
      },
      {
        title: 'Produtos táticos',
        description: 'Equipamentos táticos de alta tecnologia',
      },
      {
        title: 'Equipamentos de serviço',
        description: 'Ferramentas e equipamentos para operações federais',
      },
      {
        title: 'Itens de coleção',
        description: 'Itens especiais e colecionáveis',
      },
    ],
  },
  gm: {
    id: 'gm',
    name: 'Guarda Municipal',
    headline: 'Para quem protege o município e está sempre em movimento.',
    subheadline: 'A maior comunidade de compra e venda entre profissionais da segurança pública',
    description: 'Equipamentos, acessórios, viaturas, artigos operacionais e muito mais — publicados e negociados por quem realmente vive a rotina de rua.',
    benefits: [
      'Compra e venda direta entre operadores',
      'Perfis verificados',
      'Crescimento orgânico da comunidade (média 4% ao dia — 2 a 8 novos cadastros/dia)',
      'Mais de 140 usuários ativos e crescendo',
      'Produtos e conteúdos específicos para GM',
    ],
    whyBenefit: 'A Guarda Municipal atua na proteção do patrimônio público e da população, necessitando de equipamentos versáteis e confiáveis. Nossa plataforma reúne guardas municipais que compartilham conhecimento sobre os melhores equipamentos para o trabalho municipal.',
    categories: [
      {
        title: 'Acessórios operacionais',
        description: 'Equipamentos essenciais para o patrulhamento municipal',
      },
      {
        title: 'Viaturas e veículos',
        description: 'Veículos adaptados para operações municipais',
      },
      {
        title: 'Produtos táticos',
        description: 'Equipamentos táticos para guardas municipais',
      },
      {
        title: 'Equipamentos de serviço',
        description: 'Ferramentas e equipamentos para o trabalho municipal',
      },
      {
        title: 'Itens de coleção',
        description: 'Itens especiais e colecionáveis',
      },
    ],
  },
};

export const getForceContent = (force: string): ForceContent => {
  return forceContent[force.toLowerCase()] || forceContent.pm;
};

// Re-export getForceColors from colors.ts
export { getForceColors } from './colors';
export type { ForceColors } from './colors';

