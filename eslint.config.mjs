import tseslint from 'typescript-eslint';
export default tseslint.config({ ignores: ['**/dist/**', '**/.next/**', '**/node_modules/**', '**/next-env.d.ts', '**/SimulatorBuild/**', '**/.test-results/**'] }, ...tseslint.configs.recommended, { rules: { '@typescript-eslint/no-explicit-any': 'error' } });
