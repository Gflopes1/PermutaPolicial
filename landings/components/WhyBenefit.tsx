import React from 'react';
import { ForceColors } from '../config/colors';

interface WhyBenefitProps {
  colors: ForceColors;
  whyBenefit: string;
  forceName: string;
}

export default function WhyBenefit({ colors, whyBenefit, forceName }: WhyBenefitProps) {
  return (
    <section
      style={{
        background: `linear-gradient(135deg, ${colors.primary} 0%, ${colors.primaryDark} 100%)`,
      }}
      className="py-16 md:py-24"
    >
      <div className="container mx-auto px-4">
        <div className="max-w-4xl mx-auto text-center">
          <h2 className="text-3xl md:text-4xl font-bold text-white mb-6">
            Por que {forceName} se beneficia?
          </h2>
          <p className="text-lg md:text-xl text-white/90 leading-relaxed">
            {whyBenefit}
          </p>
        </div>
      </div>
    </section>
  );
}

