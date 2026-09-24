import React from 'react';
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

export default function GMLanding() {
  const colors = getForceColors('gm');
  const content = getForceContent('gm');

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


