import React from 'react';
import Link from 'next/link';
import { ForceColors } from '../config/colors';

interface FooterProps {
  colors: ForceColors;
}

export default function Footer({ colors }: FooterProps) {
  return (
    <footer
      style={{
        backgroundColor: colors.primaryDark,
      }}
      className="py-12"
    >
      <div className="container mx-auto px-4">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-8 mb-8">
          <div>
            <h3 className="text-white font-bold text-lg mb-4">Permuta Policial</h3>
            <p className="text-white/70 text-sm">
              A maior comunidade de compra e venda entre profissionais da segurança pública.
            </p>
          </div>
          <div>
            <h3 className="text-white font-bold text-lg mb-4">Links Rápidos</h3>
            <ul className="space-y-2">
              <li>
                <Link
                  href="https://br.permutapolicial.com.br/auth"
                  className="text-white/70 hover:text-white text-sm transition-colors"
                >
                  Criar Conta
                </Link>
              </li>
              <li>
                <Link
                  href="https://br.permutapolicial.com.br/auth"
                  className="text-white/70 hover:text-white text-sm transition-colors"
                >
                  Entrar
                </Link>
              </li>
            </ul>
          </div>
          <div>
            <h3 className="text-white font-bold text-lg mb-4">Contato</h3>
            <p className="text-white/70 text-sm">
              Suporte através da plataforma
            </p>
          </div>
        </div>
        <div
          style={{
            borderTopColor: colors.primaryLight,
          }}
          className="pt-8 border-t border-opacity-20"
        >
          <p className="text-white/50 text-sm text-center">
            © {new Date().getFullYear()} Permuta Policial. Todos os direitos reservados.
          </p>
        </div>
      </div>
    </footer>
  );
}

