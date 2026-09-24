import React from 'react';
import Head from 'next/head';
import { ForceColors } from '@/config/colors';

interface LayoutProps {
  children: React.ReactNode;
  colors: ForceColors;
  title: string;
  description: string;
  forceName: string;
}

export default function Layout({ children, colors, title, description, forceName }: LayoutProps) {
  return (
    <>
      <Head>
        <title>{title}</title>
        <meta name="description" content={description} />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <link rel="icon" href="/favicon.ico" />
      </Head>
      <div
        style={{
          backgroundColor: colors.background,
          color: colors.text,
        }}
        className="min-h-screen"
      >
        {children}
      </div>
    </>
  );
}

