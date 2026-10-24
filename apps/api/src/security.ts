import { CanActivate, ExecutionContext, Injectable, SetMetadata, UnauthorizedException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
export const Public = () => SetMetadata('public', true);
/** Fail closed until a real identity/session provider and resource authorization are implemented. */
@Injectable()
export class DefaultDenyGuard implements CanActivate {
  constructor(private readonly reflector: Reflector) {}
  canActivate(context: ExecutionContext) {
    if (this.reflector.getAllAndOverride<boolean>('public', [context.getHandler(), context.getClass()])) return true;
    throw new UnauthorizedException('Authentication is not available in this development slice');
  }
}
