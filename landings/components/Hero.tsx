import React from 'react';
import Link from 'next/link';
import { ForceColors } from '../config/colors';

interface HeroProps {
  colors: ForceColors;
  headline: string;
  subheadline: string;
  description: string;
}

export default function Hero({ colors, headline, subheadline, description }: HeroProps) {
  return (
    <section className="relative py-20 md:py-32 overflow-hidden">
      <div
        style={{
          background: `linear-gradient(135deg, ${colors.primary} 0%, ${colors.primaryDark} 100%)`,
        }}
        className="absolute inset-0 opacity-5"
      />
      <div className="container mx-auto px-4 relative z-10">
        <div className="max-w-4xl mx-auto text-center">
          <h1
            style={{ color: colors.primary }}
            className="text-4xl md:text-5xl lg:text-6xl font-bold mb-6 leading-tight"
          >
            {headline}
          </h1>
          <h2 className="text-xl md:text-2xl font-semibold mb-4 text-gray-800">
            {subheadline}
          </h2>
          <p className="text-lg md:text-xl text-gray-600 mb-10 max-w-2xl mx-auto">
            {description}
          </p>
          <div className="flex flex-col sm:flex-row gap-4 justify-center items-center">
            <Link
              href="https://br.permutapolicial.com.br/auth"
              style={{
                backgroundColor: colors.primary,
              }}
              className="px-8 py-4 rounded-lg text-white font-semibold text-lg hover:opacity-90 transition-opacity shadow-lg w-full sm:w-auto"
            >
              Criar Conta Grátis
            </Link>
            <Link
              href="https://br.permutapolicial.com.br/auth"
              style={{
                borderColor: colors.primary,
                color: colors.primary,
              }}
              className="px-8 py-4 rounded-lg border-2 font-semibold text-lg hover:bg-opacity-10 transition-colors w-full sm:w-auto"
            >
              Entrar
            </Link>
          </div>
        </div>
      </div>
    </section>
  );
}

