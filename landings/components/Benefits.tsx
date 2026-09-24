import React from 'react';
import { ForceColors } from '../config/colors';

interface BenefitsProps {
  colors: ForceColors;
  benefits: string[];
}

export default function Benefits({ colors, benefits }: BenefitsProps) {
  return (
    <section className="py-16 md:py-24">
      <div className="container mx-auto px-4">
        <div className="text-center mb-12">
          <h2
            style={{ color: colors.primary }}
            className="text-3xl md:text-4xl font-bold mb-4"
          >
            Benefícios
          </h2>
          <p className="text-lg text-gray-600 max-w-2xl mx-auto">
            Uma plataforma criada por profissionais, para profissionais
          </p>
        </div>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 max-w-6xl mx-auto">
          {benefits.map((benefit, index) => (
            <div
              key={index}
              style={{
                borderColor: colors.primaryLight,
                borderTopColor: colors.secondary,
              }}
              className="bg-white p-6 rounded-lg border-t-4 border shadow-md hover:shadow-lg transition-shadow"
            >
              <div
                style={{ color: colors.secondary }}
                className="text-3xl mb-4"
              >
                ✓
              </div>
              <p className="text-gray-700 leading-relaxed">{benefit}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

