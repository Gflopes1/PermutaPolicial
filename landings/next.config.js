/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  output: 'standalone',
  
  // Configurações de ESLint
  eslint: {
    ignoreDuringBuilds: false,
  },
  
  // Configurações de TypeScript
  typescript: {
    ignoreBuildErrors: false,
  },
  
  // Otimizações para reduzir uso de memória durante o build
  swcMinify: true,
  
  // Configurações de compilação
  compiler: {
    removeConsole: process.env.NODE_ENV === 'production',
  },
  
  // Limitar workers para reduzir uso de memória
  experimental: {
    // Reduzir workers do webpack
    webpackBuildWorker: false,
  },
  
  // Configurações de webpack para reduzir memória
  webpack: (config, { isServer }) => {
    if (!isServer) {
      // Otimizações para cliente
      config.optimization = {
        ...config.optimization,
        moduleIds: 'deterministic',
      };
    }
    return config;
  },
}

module.exports = nextConfig

