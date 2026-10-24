import { Controller, Get, Module, ServiceUnavailableException } from '@nestjs/common';
import { APP_GUARD } from '@nestjs/core';
import { ThrottlerGuard, ThrottlerModule } from '@nestjs/throttler';
import { ApiResponse, ApiTags } from '@nestjs/swagger';
import { Database } from './database';
import { PropertiesController, PropertiesService } from './properties';
import { DefaultDenyGuard, Public } from './security';
import { FirebaseAuthVerifier } from './firebase-auth';
@ApiTags('Health')
@Public()
@Controller()
class HealthController {
  constructor(private readonly database: Database) {}
  @Get('live') live() { return { status: 'up' }; }
  @Get('health') @ApiResponse({ status: 503, description: 'One or more dependencies unavailable' })
  async health() {
    const dependencies = await this.database.check();
    if (Object.values(dependencies).some(status => status !== 'up')) throw new ServiceUnavailableException({ status: 'degraded', dependencies });
    return { status: 'ready', dependencies };
  }
}
@Module({
  imports: [ThrottlerModule.forRoot([{ ttl: 60000, limit: 120 }])],
  controllers: [HealthController, PropertiesController],
  providers: [Database, PropertiesService, FirebaseAuthVerifier, { provide: APP_GUARD, useClass: DefaultDenyGuard }, { provide: APP_GUARD, useClass: ThrottlerGuard }],
})
export class AppModule {}
