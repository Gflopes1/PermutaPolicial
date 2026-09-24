import React from 'react';
import Link from 'next/link';
import { ForceColors } from '../config/colors';

interface HeaderProps {
  colors: ForceColors;
  forceName: string;
}

export default function Header({ colors, forceName }: HeaderProps) {
  return (
    <header
      style={{
        backgroundColor: colors.primary,
        borderBottom: `3px solid ${colors.secondary}`,
      }}
      className="sticky top-0 z-50 shadow-lg"
    >
      <div className="container mx-auto px-4 py-4">
        <div className="flex items-center justify-between">
          <Link href="/" className="flex items-center space-x-3">
            <div
              style={{
                backgroundColor: colors.secondary,
              }}
              className="w-10 h-10 rounded-lg flex items-center justify-center"
            >
              <span className="text-white font-bold text-xl">PP</span>
            </div>
            <div>
              <h1 className="text-white font-bold text-xl">Permuta Policial</h1>
              <p className="text-white/80 text-xs">{forceName}</p>
            </div>
          </Link>
          <nav className="hidden md:flex items-center space-x-6">
            <Link
              href="https://br.permutapolicial.com.br/auth"
              className="text-white/90 hover:text-white transition-colors font-medium"
            >
              Entrar
            </Link>
            <Link
              href="https://br.permutapolicial.com.br/auth"
              style={{
                backgroundColor: colors.secondary,
              }}
              className="px-6 py-2 rounded-lg text-white font-semibold hover:opacity-90 transition-opacity"
            >
              Criar Conta
            </Link>
          </nav>
        </div>
      </div>
    </header>
  );
}

