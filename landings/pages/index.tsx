import React from 'react';
import Link from 'next/link';

export default function Home() {
  const forces = [
    { id: 'pm', name: 'Polícia Militar', path: '/app/pm' },
    { id: 'bm', name: 'Bombeiros Militares', path: '/app/bm' },
    { id: 'pc', name: 'Polícia Civil', path: '/app/pc' },
    { id: 'prf', name: 'Polícia Rodoviária Federal', path: '/app/prf' },
    { id: 'pf', name: 'Polícia Federal', path: '/app/pf' },
    { id: 'gm', name: 'Guarda Municipal', path: '/app/gm' },
  ];

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="container mx-auto px-4 py-16">
        <div className="text-center mb-12">
          <h1 className="text-4xl md:text-5xl font-bold text-gray-900 mb-4">
            Permuta Policial
          </h1>
          <p className="text-xl text-gray-600">
            A maior comunidade de compra e venda entre profissionais da segurança pública
          </p>
        </div>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 max-w-5xl mx-auto">
          {forces.map((force) => (
            <Link
              key={force.id}
              href={force.path}
              className="bg-white p-6 rounded-lg shadow-md hover:shadow-lg transition-shadow border-t-4 border-blue-600"
            >
              <h2 className="text-xl font-bold text-gray-900 mb-2">{force.name}</h2>
              <p className="text-gray-600 text-sm">Ver landing page →</p>
            </Link>
          ))}
        </div>
        <div className="text-center mt-12">
          <Link
            href="https://br.permutapolicial.com.br/auth"
            className="inline-block px-8 py-4 bg-blue-600 text-white rounded-lg font-semibold hover:bg-blue-700 transition-colors"
          >
            Acessar Plataforma
          </Link>
        </div>
      </div>
    </div>
  );
}

