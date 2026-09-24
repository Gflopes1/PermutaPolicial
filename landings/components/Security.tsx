import React from 'react';
import { ForceColors } from '../config/colors';

interface SecurityProps {
  colors: ForceColors;
}

export default function Security({ colors }: SecurityProps) {
  const securityFeatures = [
    {
      icon: '🔒',
      title: 'Perfis Autenticados',
      description: 'Todos os usuários passam por processo de verificação de identidade',
    },
    {
      icon: '⚖️',
      title: 'Conformidade Legal',
      description: 'Plataforma em conformidade com a legislação brasileira',
    },
    {
      icon: '🛡️',
      title: 'Compliance Jurídico',
      description: 'Sem uso de símbolos oficiais, garantindo total conformidade',
    },
  ];

  return (
    <section
      style={{
        backgroundColor: colors.primaryLight + '10',
      }}
      className="py-16 md:py-24"
    >
      <div className="container mx-auto px-4">
        <div className="text-center mb-12">
          <h2
            style={{ color: colors.primary }}
            className="text-3xl md:text-4xl font-bold mb-4"
          >
            Segurança e Confiança
          </h2>
          <p className="text-lg text-gray-600 max-w-2xl mx-auto">
            Sua segurança e privacidade são nossas prioridades
          </p>
        </div>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-8 max-w-5xl mx-auto">
          {securityFeatures.map((feature, index) => (
            <div
              key={index}
              className="bg-white p-8 rounded-lg shadow-md text-center"
            >
              <div className="text-5xl mb-4">{feature.icon}</div>
              <h3
                style={{ color: colors.primary }}
                className="text-xl font-bold mb-3"
              >
                {feature.title}
              </h3>
              <p className="text-gray-600">{feature.description}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

