// /test/work/salary-calculator.test.js

const salaryCalculator = require('../../src/modules/work/salary-calculator');

describe('Salary Calculator', () => {
  describe('calcEtapasForDay', () => {
    test('deve calcular etapas corretamente para regra per_6h', () => {
      expect(salaryCalculator.calcEtapasForDay(6, 'per_6h')).toBe(1);
      expect(salaryCalculator.calcEtapasForDay(12, 'per_6h')).toBe(2);
      expect(salaryCalculator.calcEtapasForDay(5.9, 'per_6h')).toBe(0); // floor
      expect(salaryCalculator.calcEtapasForDay(11.9, 'per_6h')).toBe(1); // floor
    });

    test('deve calcular etapas corretamente para regra per_8h', () => {
      expect(salaryCalculator.calcEtapasForDay(8, 'per_8h')).toBe(1);
      expect(salaryCalculator.calcEtapasForDay(16, 'per_8h')).toBe(2);
      expect(salaryCalculator.calcEtapasForDay(7.9, 'per_8h')).toBe(0);
    });

    test('deve retornar 0 para horas <= 0', () => {
      expect(salaryCalculator.calcEtapasForDay(0, 'per_6h')).toBe(0);
      expect(salaryCalculator.calcEtapasForDay(-5, 'per_6h')).toBe(0);
    });
  });

  describe('calcIRPF', () => {
    test('deve retornar 0 para base isenta (até R$ 5.000)', () => {
      expect(salaryCalculator.calcIRPF(0)).toBe(0);
      expect(salaryCalculator.calcIRPF(4000)).toBe(0);
      expect(salaryCalculator.calcIRPF(5000)).toBe(0);
    });

    test('deve aplicar redutor na faixa de transição (R$ 6.000)', () => {
      const base = 6000;
      const tradicional = salaryCalculator.calcIRPFTradicional(base);
      const redutor = 978.62 - (0.133145 * base);
      const esperado = Math.max(0, Math.round((tradicional - redutor) * 100) / 100);
      expect(salaryCalculator.calcIRPF(base)).toBe(esperado);
      expect(salaryCalculator.calcIRPF(base)).toBe(561.52);
    });

    test('deve aplicar tabela integral acima de R$ 7.350', () => {
      const base = 8000;
      const tradicional = Math.max(0, Math.round(salaryCalculator.calcIRPFTradicional(base) * 100) / 100);
      expect(salaryCalculator.calcIRPF(base)).toBe(tradicional);
    });

    test('deve aplicar trava IRPFM acima de R$ 50.000', () => {
      const base = 51000;
      const tradicional = Math.max(0, Math.round(salaryCalculator.calcIRPFTradicional(base) * 100) / 100);
      const irpfm = Math.round(base * 0.10 * 100) / 100;
      expect(salaryCalculator.calcIRPF(base)).toBe(Math.max(tradicional, irpfm));
    });
  });

  describe('calcSalaryMonth', () => {
    const defaultSettings = {
      carga_horaria_dia: 5.7,
      valor_hora_extra: 44.0,
      vale_alimentacao: 426.0,
      etapa_value: 11.0,
      previdencia_aliquota: 0.14,
      etapa_rule: 'per_6h',
      abatimento_horas: 5.7,
      salario_base: 5000.0,
    };

    test('deve calcular salário corretamente para mês com 30 dias', () => {
      const workDays = [
        { tipo: 'normal', total_hours: 8.0, etapas: 1, flag_abatimento: false },
        { tipo: 'normal', total_hours: 8.0, etapas: 1, flag_abatimento: false },
        { tipo: 'folga', total_hours: 0, etapas: 0, flag_abatimento: false },
      ];

      const result = salaryCalculator.calcSalaryMonth(workDays, defaultSettings, 4, 2024);
      
      expect(result.total_horas).toBe(16.0);
      expect(result.carga_horaria_mes).toBe(171.0); // 30 * 5.7
      expect(result.horas_extras).toBe(0); // 16 < 171
      expect(result.total_etapas).toBe(2);
      expect(result.valor_etapas).toBe(22.0); // 2 * 11
      expect(result.vale_alimentacao).toBe(426.0);
    });

    test('não deve creditar VA em mês com férias', () => {
      const workDays = [
        { tipo: 'ferias', total_hours: 0, etapas: 0, flag_abatimento: false },
      ];

      const result = salaryCalculator.calcSalaryMonth(workDays, defaultSettings, 4, 2024);
      
      expect(result.dias_ferias).toBe(1);
      expect(result.vale_alimentacao).toBe(0);
    });

    test('deve calcular horas extras corretamente', () => {
      const workDays = [];
      // Cria 30 dias com 8h cada = 240h total
      for (let i = 0; i < 30; i++) {
        workDays.push({
          tipo: 'normal',
          total_hours: 8.0,
          etapas: 1,
          flag_abatimento: false,
        });
      }

      const result = salaryCalculator.calcSalaryMonth(workDays, defaultSettings, 4, 2024);
      
      expect(result.total_horas).toBe(240.0);
      expect(result.carga_horaria_mes).toBe(171.0); // 30 * 5.7
      expect(result.horas_extras).toBe(69.0); // 240 - 171
      expect(result.valor_horas_extras).toBe(3036.0); // 69 * 44
    });
  });

  describe('computeOverlapMinutes', () => {
    test('deve calcular sobreposição corretamente', () => {
      const start1 = new Date('2024-01-01T08:00:00');
      const end1 = new Date('2024-01-01T12:00:00');
      const start2 = new Date('2024-01-01T10:00:00');
      const end2 = new Date('2024-01-01T14:00:00');

      const overlap = salaryCalculator.computeOverlapMinutes(start1, end1, start2, end2);
      expect(overlap).toBe(120); // 2 horas = 120 minutos
    });

    test('deve retornar 0 quando não há sobreposição', () => {
      const start1 = new Date('2024-01-01T08:00:00');
      const end1 = new Date('2024-01-01T12:00:00');
      const start2 = new Date('2024-01-01T14:00:00');
      const end2 = new Date('2024-01-01T18:00:00');

      const overlap = salaryCalculator.computeOverlapMinutes(start1, end1, start2, end2);
      expect(overlap).toBe(0);
    });
  });
});


