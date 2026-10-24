export interface Config {
  environment: 'development' | 'test' | 'staging' | 'production';
  demo: boolean;
  port: number;
  mongoUri: string;
  postgresUrl: string;
  redisUrl: string;
}
export function loadConfig(env: NodeJS.ProcessEnv = process.env): Config {
  const environment = env.NODE_ENV ?? 'development';
  if (!['development', 'test', 'staging', 'production'].includes(environment)) throw new Error('Invalid NODE_ENV');
  if (!['true', 'false'].includes(env.DEMO_MODE ?? '')) throw new Error('DEMO_MODE must be explicit');
  if (environment === 'production' && env.DEMO_MODE === 'true') throw new Error('Demo is forbidden in production');
  const port = Number(env.PORT ?? 3001);
  if (!Number.isInteger(port) || port < 1 || port > 65535) throw new Error('Invalid PORT');
  const required = (key: string, protocols: string[]) => {
    const value = env[key];
    try { if (!value || !protocols.includes(new URL(value).protocol)) throw new Error(); }
    catch { throw new Error(`Invalid ${key}`); }
    return value!;
  };
  return {
    environment: environment as Config['environment'], demo: env.DEMO_MODE === 'true', port,
    mongoUri: required('MONGODB_URI', ['mongodb:', 'mongodb+srv:']),
    postgresUrl: required('POSTGRES_URL', ['postgres:', 'postgresql:']),
    redisUrl: required('REDIS_URL', ['redis:', 'rediss:']),
  };
}
