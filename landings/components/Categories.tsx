import React from 'react';
import { ForceColors } from '../config/colors';

interface Category {
  title: string;
  description: string;
}

interface CategoriesProps {
  colors: ForceColors;
  categories: Category[];
}

export default function Categories({ colors, categories }: CategoriesProps) {
  return (
    <section className="py-16 md:py-24">
      <div className="container mx-auto px-4">
        <div className="text-center mb-12">
          <h2
            style={{ color: colors.primary }}
            className="text-3xl md:text-4xl font-bold mb-4"
          >
            Categorias de Produtos
          </h2>
          <p className="text-lg text-gray-600 max-w-2xl mx-auto">
            Encontre exatamente o que você precisa
          </p>
        </div>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 max-w-6xl mx-auto">
          {categories.map((category, index) => (
            <div
              key={index}
              style={{
                borderLeftColor: colors.secondary,
              }}
              className="bg-white p-6 rounded-lg border-l-4 shadow-md hover:shadow-lg transition-shadow"
            >
              <h3
                style={{ color: colors.primary }}
                className="text-xl font-bold mb-2"
              >
                {category.title}
              </h3>
              <p className="text-gray-600">{category.description}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

