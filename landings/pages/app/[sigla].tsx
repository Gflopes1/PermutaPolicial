import React, { useEffect } from 'react';
import { useRouter } from 'next/router';
import Layout from '../../components/Layout';
import Header from '../../components/Header';
import Hero from '../../components/Hero';
import Benefits from '../../components/Benefits';
import Security from '../../components/Security';
import Categories from '../../components/Categories';
import WhyBenefit from '../../components/WhyBenefit';
import CTA from '../../components/CTA';
import Footer from '../../components/Footer';
import { getForceColors, getForceContent } from '../../config/content';

export default function LandingPage() {
  const router = useRouter();
  const { sigla } = router.query;

  // Valida se a sigla é válida
  const validForces = React.useMemo(() => ['pm', 'bm', 'pc', 'prf', 'pf', 'gm'], []);
  const force = validForces.includes(sigla as string) ? (sigla as string) : 'pm';

  const colors = getForceColors(force);
  const content = getForceContent(force);

  // Se a sigla não for válida, redireciona para PM
  useEffect(() => {
    if (sigla && !validForces.includes(sigla as string)) {
      router.replace('/app/pm');
    }
  }, [sigla, router, validForces]);

  // Se ainda não carregou ou sigla inválida, mostra loading
  if (!router.isReady || (sigla && !validForces.includes(sigla as string))) {
    return null;
  }

  return (
    <Layout
      colors={colors}
      title={`${content.name} - Permuta Policial`}
      description={content.description}
      forceName={content.name}
    >
      <Header colors={colors} forceName={content.name} />
      <Hero
        colors={colors}
        headline={content.headline}
        subheadline={content.subheadline}
        description={content.description}
      />
      <Benefits colors={colors} benefits={content.benefits} />
      <Security colors={colors} />
      <Categories colors={colors} categories={content.categories} />
      <WhyBenefit
        colors={colors}
        whyBenefit={content.whyBenefit}
        forceName={content.name}
      />
      <CTA colors={colors} />
      <Footer colors={colors} />
    </Layout>
  );
}

