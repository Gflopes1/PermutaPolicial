import React from 'react';
import Link from 'next/link';
import { ForceColors } from '../config/colors';

interface CTAProps {
  colors: ForceColors;
}

export default function CTA({ colors }: CTAProps) {
  return (
    <section className="py-16 md:py-24">
      <div className="container mx-auto px-4">
        <div
          style={{
            backgroundColor: colors.primaryLight + '10',
            borderColor: colors.secondary,
          }}
          className="max-w-4xl mx-auto bg-white p-8 md:p-12 rounded-2xl border-t-4 shadow-xl"
        >
          <div className="text-center">
            <h2
              style={{ color: colors.primary }}
              className="text-3xl md:text-4xl font-bold mb-4"
            >
              Pronto para começar?
            </h2>
            <p className="text-lg text-gray-600 mb-8">
              Junte-se à comunidade de profissionais da segurança pública
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
            <div className="mt-8 pt-8 border-t border-gray-200">
              <p className="text-sm text-gray-500 mb-4">Também disponível como app</p>
              <div className="flex justify-center gap-4">
                <button
                  disabled
                  className="px-6 py-3 bg-gray-200 text-gray-500 rounded-lg font-medium cursor-not-allowed"
                >
                  📱 Em breve
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}

